local M = {}

M.defaults = {
  enabled = true,
  filetypes = { "", "text" },
  magika_cmd = { "magika", "--json" },
  timeout_ms = 1500,
  confidence_threshold = 0.8,
  cache = true,
}

function M.merge(opts)
  return vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
