local config = require("magika.config")
local detect = require("magika.detect")

local M = {}

local state = {
  options = config.merge(),
  initialized = false,
}

local function create_user_command()
vim.api.nvim_create_user_command("MagikaDetect", function(command_opts)
    local target = command_opts.args ~= "" and tonumber(command_opts.args) or 0
    M.detect(target, { force = true })
  end, {
    desc = "Run Magika fallback filetype detection for a buffer",
    nargs = "?",
  })
end

local function create_autocmds()
  local group = vim.api.nvim_create_augroup("magika", { clear = true })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    callback = function(args)
      M.maybe_detect(args.buf)
    end,
  })
end

function M.setup(opts)
  state.options = config.merge(opts)

  if state.initialized then
    return
  end

  create_autocmds()
  create_user_command()
  state.initialized = true
end

function M.maybe_detect(buf)
  if not state.options.enabled then
    return
  end

  detect.maybe(buf or 0, state.options)
end

function M.detect(buf, run_opts)
  if not state.options.enabled then
    return
  end

  detect.run(buf or 0, run_opts or { force = true }, state.options)
end

return M
