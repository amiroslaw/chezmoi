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
local gemini_api_key = env("GEMINI_API_KEY", env("GOOGLE_API_KEY", ""))

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

local function gemini_response_text(response)
  if not response or response == "" then
    return nil
  end

  local json = response:gsub("^data:%s*", ""):gsub("%s+$", "")
  if json == "[DONE]" then
    return nil
  end

  local ok, data = pcall(vim.json.decode, json)
  if not ok or type(data) ~= "table" then
    return nil
  end
  if data.error then
    require("parrot.logger").error(
      "Gemini: " .. (data.error.message or tostring(data.error))
    )
    return nil
  end

  local candidate = data.candidates and data.candidates[1]
  local parts = candidate and candidate.content and candidate.content.parts
  if type(parts) ~= "table" then
    return nil
  end

  local text = {}
  for _, part in ipairs(parts) do
    if type(part.text) == "string" and not part.thought then
      text[#text + 1] = part.text
    end
  end
  if #text == 0 then
    return nil
  end
  return table.concat(text)
end

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
      -- Keep text/chat Gemini models, skip image, audio, research and other
      -- special-purpose models that are not useful for editing notes.
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

local function gemini_payload(payload)
  local contents = {}
  local system_instruction = nil

  for _, message in ipairs(payload.messages or {}) do
    local text = (message.content or ""):gsub("^%s*(.-)%s*$", "%1")
    if message.role == "system" then
      if text ~= "" then
        if system_instruction == nil then
          system_instruction = { parts = {} }
        end
        system_instruction.parts[#system_instruction.parts + 1] = { text = text }
      end
    else
      local role = message.role == "assistant" and "model" or "user"
      contents[#contents + 1] = { role = role, parts = { { text = text } } }
    end
  end

  local generation_config = {
    temperature = payload.temperature,
    topP = payload.top_p,
    topK = payload.top_k or payload.topK,
    maxOutputTokens = payload.max_tokens or payload.maxOutputTokens,
  }

  return {
    contents = contents,
    generationConfig = generation_config,
    systemInstruction = system_instruction,
  }
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
if gemini_api_key ~= "" then
  providers.gemini = {
    name = "gemini",
    endpoint = function(self)
      return "https://generativelanguage.googleapis.com/v1beta/models/"
        .. self._model
        .. ":streamGenerateContent?alt=sse"
    end,
    model_endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
    api_key = gemini_api_key,
    params = {
      chat = { temperature = 0.7, top_p = 0.95, maxOutputTokens = 8192 },
      command = { temperature = 0.3, top_p = 0.95, maxOutputTokens = 8192 },
    },
    topic = {
      model = "gemini-2.5-flash-lite",
      params = { maxOutputTokens = 64 },
    },
    headers = function(self)
      return {
        ["Content-Type"] = "application/json",
        ["x-goog-api-key"] = self.api_key,
      }
    end,
    models = {
      "gemini-2.5-flash",
      "gemini-2.5-flash-lite",
      "gemini-2.5-pro",
    },
    get_available_models = gemini_models,
    preprocess_payload = gemini_payload,
    process_stdout = gemini_response_text,
    process_onexit = gemini_response_text,
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

local function run_action(parrot, params, action)
  params = selection_or_file(params)
  if not action.keep_args then
    params.args = ""
  end

  local target = parrot.ui.Target[action.target] or parrot.ui.Target.rewrite
  local model_type = action.target == "popup" and "chat" or "command"
  local model_obj = parrot.get_model(model_type)
  parrot.Prompt(params, target, model_obj, action.prompt, action.template)
end

local hooks = {}

for name, action in pairs(actions) do
  local current = action
  hooks[name] = function(parrot, params)
    run_action(parrot, params, current)
  end
end

hooks.Translate = function(parrot, params)
  local requested = (params.args or ""):lower()
  requested = requested:match("%S+") or ""

  local instruction
  if requested == "pl" or requested == "polish" then
    instruction = prompts.translate.pl
  elseif requested == "en" or requested == "english" then
    instruction = prompts.translate.en
  else
    instruction = prompts.translate.auto
  end

  run_action(parrot, params, {
    target = "rewrite",
    template = instruction .. "\n{{selection}}",
  })
end

hooks.EditWithInstruction = function(parrot, params)
  run_action(parrot, params, {
    target = "rewrite",
    keep_args = true,
    prompt = prompts.edit_with_instruction.prompt,
    template = prompts.edit_with_instruction.template,
  })
end

hooks.Ask = function(parrot, params)
  run_action(parrot, params, {
    target = "popup",
    keep_args = true,
    prompt = prompts.ask.prompt,
    template = prompts.ask.template,
  })
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

    -- Changes are shown as a diff; press Enter/a to apply. This is also safer
    -- for whole-file translations.
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
