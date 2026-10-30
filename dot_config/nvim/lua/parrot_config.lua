-- parrot.nvim configuration
-- https://github.com/frankroeder/parrot.nvim
--
-- Providers: Ollama (default) and Google Gemini.
-- All Parrot commands are available as :Prt<Name>, e.g. :PrtGrammar.
-- The key mappings live in init.lua (the <LocalLeader>o... group).

local M = {}

-- All prompt texts live in lua/parrot_prompts.lua.
local prompts = require("parrot_prompts")

local function env(name, default)
  local value = os.getenv(name)
  if value == nil or value == "" then
    return default
  end
  return value
end

local ollama_host = env("OLLAMA_API_HOST", "http://localhost:11434"):gsub("/+$", "")
local ollama_model = env("OLLAMA_MODEL", "qwen2.5:3b")
local gemini_api_key = os.getenv("GEMINI_API_KEY")

-- Run a model-list request with curl. `args` are the arguments that parrot
-- prepared from `model_endpoint` + provider headers.
local function curl_json(args)
  local cmd = vim.list_extend({ "curl", "-sS" }, args or {})
  local res = vim.system(cmd, { text = true }):wait(5000)
  if not res or res.code ~= 0 then
    return nil
  end
  local ok, data = pcall(vim.json.decode, res.stdout or "")
  if not ok then
    return nil
  end
  return data
end

-- Ollama returns `{ models = { { name = "qwen2.5:3b" }, ... } }`.
local function ollama_models(self, args)
  local data = curl_json(args)
  if not data or type(data.models) ~= "table" then
    return self.models
  end

  local names = {}
  for _, item in ipairs(data.models) do
    if item.name then
      names[#names + 1] = item.name
    end
  end
  if #names == 0 then
    return self.models
  end

  table.sort(names)
  -- Keep the configured model as the first/default one.
  for i, name in ipairs(names) do
    if name == ollama_model then
      table.remove(names, i)
      table.insert(names, 1, ollama_model)
      break
    end
  end
  return names
end

-- Gemini returns a long list that also contains image, audio, research and
-- embedding models. Keep only models that can be used for text generation.
local function gemini_models(self, args)
  local data = curl_json(args)
  if not data or type(data.models) ~= "table" then
    return self.models
  end

  local names = {}
  for _, item in ipairs(data.models) do
    if item.name then
      local methods = item.supportedGenerationMethods
      local supports_generate = methods == nil or vim.tbl_contains(methods, "generateContent")
      local name = item.name:gsub("^models/", "")
      local lower = name:lower()
      local is_text_model = lower:match("^gemini")
        and not lower:match("image")
        and not lower:match("tts")
        and not lower:match("transcribe")
        and not lower:match("computer%-use")
        and not lower:match("robotics")
        and not lower:match("omni")
        and not lower:match("nano%-banana")
        and not lower:match("deep%-research")
        and not lower:match("antigravity")
        and not lower:match("lyria")
      if supports_generate and is_text_model then
        names[#names + 1] = name
      end
    end
  end
  if #names == 0 then
    return self.models
  end
  table.sort(names)
  return names
end

local function ollama_payload(payload)
  local options = {}

  local option_keys = { "temperature", "top_p", "top_k", "num_ctx", "min_p", "repeat_penalty", "seed" }
  for _, key in ipairs(option_keys) do
    if payload[key] ~= nil then
      options[key] = payload[key]
      payload[key] = nil
    end
  end
  -- Parrot/OpenAI spelling -> Ollama spelling
  if payload.max_tokens ~= nil then
    options.num_predict = payload.max_tokens
    payload.max_tokens = nil
  end
  if payload.max_completion_tokens ~= nil then
    options.num_predict = payload.max_completion_tokens
    payload.max_completion_tokens = nil
  end

  payload.options = vim.tbl_extend("force", options, payload.options or {})
  return payload
end

local providers = {
  ollama = {
    name = "ollama",
    endpoint = ollama_host .. "/api/chat",
    model_endpoint = ollama_host .. "/api/tags",
    api_key = env("OLLAMA_API_KEY", ""),
    params = {
      chat = { temperature = 0.4, top_p = 1, num_ctx = 8192 },
      command = { temperature = 0.2, top_p = 1, num_ctx = 8192 },
    },
    topic = {
      model = ollama_model,
      params = { max_tokens = 32 },
    },
    headers = {
      ["Content-Type"] = "application/json",
    },
    models = { ollama_model },
    resolve_api_key = function()
      return true
    end,
    get_available_models = ollama_models,
    preprocess_payload = ollama_payload,
    process_stdout = function(response)
      if not response or response == "" then
        return nil
      end
      local ok, data = pcall(vim.json.decode, response)
      if not ok or type(data) ~= "table" then
        return nil
      end
      if data.error then
        require("parrot.logger").error("Ollama: " .. (data.error.message or tostring(data.error)))
        return nil
      end
      return data.message and data.message.content or nil
    end,
  },
}

-- Gemini is only registered when a key is available, because parrot validates
-- every configured provider at startup.
if gemini_api_key and gemini_api_key ~= "" then
  providers.gemini = {
    name = "gemini",
    endpoint = function(self)
      return "https://generativelanguage.googleapis.com/v1beta/models/"
        .. self._model
        .. ":streamGenerateContent?alt=sse"
    end,
    model_endpoint = function(self)
      return { "https://generativelanguage.googleapis.com/v1beta/models?key=" .. self.api_key }
    end,
    api_key = gemini_api_key,
    params = {
      chat = { temperature = 1.1, topP = 1, topK = 10, maxOutputTokens = 8192 },
      command = { temperature = 0.8, topP = 1, topK = 10, maxOutputTokens = 8192 },
    },
    topic = {
      model = "gemini-3.5-flash-lite",
      params = { maxOutputTokens = 64 },
    },
    headers = function(self)
      return {
        ["Content-Type"] = "application/json",
        ["x-goog-api-key"] = self.api_key,
      }
    end,
    models = {
      "gemini-3.8-flash",
      "gemini-3.6-flash",
      "gemini-3.5-flash-lite",
      "gemini-3.1-flash-lite",
    },
    get_available_models = gemini_models,
    preprocess_payload = function(payload)
      local contents = {}
      local system_instruction = nil
      for _, message in ipairs(payload.messages) do
        if message.role == "system" then
          system_instruction = { parts = { { text = message.content } } }
        else
          local role = message.role == "assistant" and "model" or "user"
          table.insert(
            contents,
            { role = role, parts = { { text = message.content:gsub("^%s*(.-)%s*$", "%1") } } }
          )
        end
      end
      local gemini_payload = {
        contents = contents,
        generationConfig = {
          temperature = payload.temperature,
          topP = payload.topP or payload.top_p,
          -- topK is set in `params` above and would otherwise be ignored.
          topK = payload.topK or payload.top_k,
          maxOutputTokens = payload.max_tokens or payload.maxOutputTokens,
        },
      }
      if system_instruction then
        gemini_payload.systemInstruction = system_instruction
      end
      return gemini_payload
    end,
    process_stdout = function(response)
      if not response or response == "" then
        return nil
      end
      local success, decoded = pcall(vim.json.decode, response)
      if
        success
        and decoded.candidates
        and decoded.candidates[1]
        and decoded.candidates[1].content
        and decoded.candidates[1].content.parts
        and decoded.candidates[1].content.parts[1]
      then
        return decoded.candidates[1].content.parts[1].text
      end
      return nil
    end,
  }
end

-- Actions are defined in lua/parrot_prompts.lua. Each one becomes :Prt<Name>.
-- A selection is used when there is one; otherwise the hook runs on the whole
-- file (see `selection_or_file` below).
local actions = prompts.actions

-- Make the text of the selection available to a command. Without a visual
-- selection, use the whole file (the same behaviour as the old ogpt actions).
local function selection_or_file(params)
  if params.range ~= 2 then
    local buf = vim.api.nvim_get_current_buf()
    params.range = 2
    params.line1 = 1
    params.line2 = vim.api.nvim_buf_line_count(buf)
  end
  return params
end

--- Resolves the provider instance for a prompt action, taking into account
--- optional action.provider or action.model overrides.
---@param parrot table Parrot config module
---@param is_chat boolean Whether this is a chat target
---@param action table Action definition table
---@return table|nil provider instance
local function resolve_provider(parrot, is_chat, action)
  local chat_handler = parrot.chat_handler
  if not chat_handler then
    return nil
  end

  local function init_prov(name)
    local cfg = chat_handler.providers[name]
    if cfg then
      local init_provider = require("parrot.provider").init_provider
      return init_provider(cfg)
    end
    return nil
  end

  if action.provider then
    local prov = init_prov(action.provider)
    if prov then
      return prov
    end
  end

  if action.model then
    local current_prov = chat_handler:get_provider(is_chat)
    if current_prov then
      local cfg = chat_handler.providers[current_prov.name]
      if cfg and cfg.models and vim.tbl_contains(cfg.models, action.model) then
        return current_prov
      end
    end

    for prov_name, prov_cfg in pairs(chat_handler.providers) do
      if prov_cfg.models and vim.tbl_contains(prov_cfg.models, action.model) then
        local prov = init_prov(prov_name)
        if prov then
          return prov
        end
      end
    end
  end

  return chat_handler:get_provider(is_chat)
end

local function run_action(parrot, params, action)
  params = selection_or_file(params)
  if not action.keep_args then
    params.args = ""
  end

  local target = parrot.ui.Target[action.target] or parrot.ui.Target.rewrite
  local model_type = action.target == "popup" and "chat" or "command"

  local model_obj
  if action.model and action.model ~= "" then
    local prov = resolve_provider(parrot, action.target == "popup", action)
    local sys_prompt = (parrot.chat_handler
      and parrot.chat_handler.options
      and parrot.chat_handler.options.system_prompt
      and parrot.chat_handler.options.system_prompt[model_type]) or ""

    model_obj = {
      name = action.model,
      provider = prov,
      system_prompt = sys_prompt,
    }
  else
    model_obj = parrot.get_model(model_type)
  end

  parrot.Prompt(params, target, model_obj, action.prompt, action.template)
end

local hooks = {}

for name, action in pairs(actions) do
  local current = action
  hooks[name] = function(parrot, params)
    run_action(parrot, params, current)
  end
end

hooks.EditWithInstruction = function(parrot, params)
  run_action(parrot, params, {
    target = "rewrite",
    keep_args = true,
    prompt = prompts.edit_with_instruction.prompt,
    template = prompts.edit_with_instruction.template,
  })
end

hooks.AskText = function(parrot, params)
  run_action(parrot, params, {
    target = "popup",
    keep_args = true,
    prompt = prompts.ask_about_text.prompt,
    template = prompts.ask_about_text.template,
  })
end

--- Strip whitespace and a Markdown fence that wraps the whole summary.
local function clean_summary(text)
  text = (text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  local fenced = text:match("^```[%w_-]*\n(.-)\n```$")
  if fenced then
    text = fenced:gsub("^%s+", ""):gsub("%s+$", "")
  end
  return text
end

--- Replace everything after the chat header with a summary exchange.
--- Keeping the header and using the normal prefixes makes the file a valid
--- Parrot chat that can continue with the compacted conversation as context.
---@return boolean ok, string|nil err
local function replace_chat_with_summary(parrot, buf, summary)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local Conversation = require("parrot.conversation")
  local _, header_end = Conversation.parse_headers(lines)
  if header_end == nil then
    return false, "the chat header separator ('---') is missing"
  end

  -- header_end is the 0-based index of the `---` line.
  local new_lines = vim.list_slice(lines, 1, header_end + 1)
  new_lines[#new_lines + 1] = parrot.options.chat_user_prefix
  new_lines[#new_lines + 1] = "Summarize the conversation so far."
  new_lines[#new_lines + 1] = ""
  new_lines[#new_lines + 1] = parrot.options.llm_prefix
  for _, line in ipairs(vim.split(summary, "\n", { plain = true })) do
    new_lines[#new_lines + 1] = line
  end
  new_lines[#new_lines + 1] = ""
  new_lines[#new_lines + 1] = parrot.options.chat_user_prefix

  local ok, err = pcall(function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("silent write!")
    end)
  end)
  if not ok then
    return false, err
  end

  if vim.api.nvim_get_current_buf() == buf then
    vim.api.nvim_win_set_cursor(0, { #new_lines, 0 })
  end
  return true
end

--- Summarize the whole current chat and replace its conversation with that
--- summary. The optional command argument is passed to the model as an extra
--- focus for the summary, e.g. `:PrtCompact keep the API decisions`.
local function compact_chat(parrot, params)
  params = params or {}

  local buf = vim.api.nvim_get_current_buf()
  local file_name = vim.api.nvim_buf_get_name(buf)
  local utils = require("parrot.utils")
  if not utils.is_chat(buf, file_name, parrot.options.chat_dir) then
    parrot.logger.warning("PrtCompact only works in a Parrot chat buffer")
    return
  end

  local chat = parrot.chat_handler
  if not chat.pool:unique_for_buffer(buf) then
    parrot.logger.warning("Cannot compact this chat while a request is running")
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local Conversation = require("parrot.conversation")
  local model_obj = chat:get_model("chat")
  if not model_obj or not model_obj.provider or not model_obj.name then
    parrot.logger.error("Cannot compact chat: no chat model is available")
    return
  end
  local conversation, headers_or_error = Conversation.from_chat_buffer(lines, {
    user_prefix = parrot.options.chat_user_prefix,
    llm_prefix = parrot.options.llm_prefix,
    system_prompt = model_obj.system_prompt,
  })
  if not conversation then
    parrot.logger.error("Cannot compact chat: " .. tostring(headers_or_error))
    return
  end

  local has_content = false
  for _, message in ipairs(conversation:get_messages()) do
    if message.role ~= "system" and message.content:match("%S") then
      has_content = true
      break
    end
  end
  if not has_content then
    parrot.logger.warning("There is no conversation to compact")
    return
  end

  local focus = (params.args or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local compact_prompt = prompts.compact.template
  if focus ~= "" then
    compact_prompt = compact_prompt .. "\n\nFocus this summary on:\n" .. focus
  end
  conversation:add_user_message(compact_prompt)

  local provider = model_obj.provider
  local provider_cfg = parrot.providers[provider.name] or {}
  local request_params = {}
  if provider_cfg.params then
    request_params =
      provider_cfg.params.compact or provider_cfg.params.command or provider_cfg.params.chat or {}
  end
  request_params = vim.deepcopy(request_params)

  provider:set_model(model_obj.name)
  if not provider:verify() then
    parrot.logger.error("Cannot compact chat: provider " .. provider.name .. " is not configured")
    return
  end

  local payload = utils.prepare_payload(conversation:get_messages(), model_obj.name, request_params)
  if not payload then
    parrot.logger.error("Cannot compact chat: could not prepare the request")
    return
  end

  local spinner = nil
  if parrot.options.enable_spinner then
    spinner = require("parrot.spinner"):new(parrot.options.spinner_type)
    spinner:start("compacting chat...", true)
  end

  -- Do not overwrite messages the user types while the summary is generated.
  local changedtick = vim.api.nvim_buf_get_changedtick(buf)

  chat:query(buf, provider, payload, function() end, vim.schedule_wrap(function(qid)
    local qt = chat.queries:get(qid)
    local summary = clean_summary(qt and qt.response)
    local failed = not qt or qt.error_occurred or summary == ""
    if spinner then
      spinner:stop(failed)
    end
    if failed then
      parrot.logger.error("Compacting chat failed")
      return
    end

    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    if vim.api.nvim_buf_get_changedtick(buf) ~= changedtick then
      parrot.logger.warning("The chat changed while compacting, so the summary was discarded")
      return
    end

    local ok, err = replace_chat_with_summary(parrot, buf, summary)
    if not ok then
      parrot.logger.error("Cannot compact chat: " .. tostring(err))
      return
    end
    parrot.logger.info("Chat compacted. The summary replaced the conversation.")
  end))
end

hooks.Compact = function(parrot, params)
  compact_chat(parrot, params)
end

--- Public entry point, e.g. require("parrot_config").compact_chat({}).
--- The :PrtCompact command calls the same function.
function M.compact_chat(params)
  local parrot = require("parrot.config")
  if not parrot.chat_handler then
    parrot.logger.error("Parrot is not initialized yet")
    return
  end
  compact_chat(parrot, params or {})
end

function M.setup()
  local state_file = vim.fn.stdpath("data") .. "/parrot/persisted/state.json"
  local first_run = vim.fn.filereadable(state_file) == 0

  require("parrot").setup({
    providers = providers,

    system_prompt = prompts.system,

    hooks = hooks,

    toggle_target = "vsplit",
    user_input_ui = "native",
    enable_spinner = true,
    show_context_hints = true,

    -- Changes are shown as a diff; press Enter/a to apply. 
    enable_preview_mode = true,
    preview_auto_apply = false,

    chat_shortcut_respond = { modes = { "n", "i", "v", "x" }, shortcut = "<C-g><C-g>" },
    chat_shortcut_delete = { modes = { "n", "i", "v", "x" }, shortcut = "<C-g>d" },
    chat_shortcut_stop = { modes = { "n", "i", "v", "x" }, shortcut = "<C-g>s" },
    chat_shortcut_new = { modes = { "n", "i", "v", "x" }, shortcut = "<C-g>c" },
  })

  -- Keep Ollama as the default on a fresh installation. On later starts the
  -- provider/model chosen with :PrtProvider / :PrtModel is restored from state.
  if first_run and providers.ollama then
    local parrot = require("parrot")
    if parrot.chat_handler then
      parrot.chat_handler:set_provider("ollama", true)
      parrot.chat_handler:set_provider("ollama", false)
    end
  end
end

return M
