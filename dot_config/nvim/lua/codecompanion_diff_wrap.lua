local M = {}

local function wrap_line(line, width)
  if line == "" then
    return { "" }
  end
  if vim.fn.strdisplaywidth(line) <= width then
    return { line }
  end

  local out, current, current_width = {}, {}, 0
  for _, char in ipairs(vim.fn.split(line, "\\zs")) do
    local char_width = vim.fn.strdisplaywidth(char)
    if current_width > 0 and current_width + char_width > width then
      table.insert(out, table.concat(current))
      current, current_width = {}, 0
    end
    table.insert(current, char)
    current_width = current_width + char_width
  end
  if #current > 0 then
    table.insert(out, table.concat(current))
  end
  return out
end

function M.setup()
  local diff_utils = require("codecompanion.diff.utils")
  if diff_utils._cc_wrap_patched then
    return
  end
  diff_utils._cc_wrap_patched = true

  local create_vl = diff_utils.create_vl
  diff_utils.create_vl = function(source, opts)
    if type(source) == "string" and opts and opts.bg == "CodeCompanionDiffDelete" then
      local info = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
      local width = info and (info.width - info.textoff) or vim.o.columns
      local wrapped = {}
      for _, line in ipairs(vim.split(source, "\n", { plain = true })) do
        vim.list_extend(wrapped, wrap_line(line, math.max(20, width - 1)))
      end
      source = table.concat(wrapped, "\n")
    end
    return create_vl(source, opts)
  end
end

return M
