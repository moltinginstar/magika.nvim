local uv = vim.uv or vim.loop

local cache = require("magika.cache")
local magika = require("magika.magika")

local M = {}

local function filetype_allowed(filetype, opts)
  local configured = opts.filetypes
  if type(configured) == "function" then
    return configured(filetype) == true
  end

  if configured == "*" then
    return true
  end

  if type(configured) == "table" then
    return vim.tbl_contains(configured, filetype)
  end

  return false
end

local function should_run(buf, opts, force)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if force then
    return true
  end

  if vim.bo[buf].buftype ~= "" then
    return false
  end

  local filetype = vim.bo[buf].filetype
  if not filetype_allowed(filetype, opts) then
    return false
  end

  return true
end

local function get_path(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    return nil
  end

  return path
end

local function get_stat(path)
  local stat = uv.fs_stat(path)
  if not stat or stat.type ~= "file" then
    return nil
  end

  return stat
end

local function cache_key(path, stat)
  local mtime = stat.mtime or {}
  return table.concat({
    path,
    tostring(mtime.sec or 0),
    tostring(mtime.nsec or 0),
    tostring(stat.size or 0),
  }, "\n")
end

function M.apply(buf, filetype, opts, run_opts)
  if not vim.api.nvim_buf_is_valid(buf) or type(filetype) ~= "string" or filetype == "" then
    return
  end

  if not run_opts.force and not filetype_allowed(vim.bo[buf].filetype, opts) then
    return
  end

  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    if not run_opts.force and not filetype_allowed(vim.bo[buf].filetype, opts) then
      return
    end

    vim.api.nvim_buf_call(buf, function()
      if vim.bo[buf].filetype ~= "" then
        vim.bo[buf].filetype = ""
      end
      vim.cmd("setfiletype " .. filetype)
    end)
  end)
end

function M.run(buf, run_opts, opts)
  run_opts = run_opts or {}
  if not should_run(buf, opts, run_opts.force == true) then
    return
  end

  local path = get_path(buf)
  if not path then
    return
  end

  local stat = get_stat(path)
  if not stat then
    return
  end

  local key = cache_key(path, stat)
  if opts.cache then
    local cached = cache.get(key)
    if cached then
      M.apply(buf, cached, opts, run_opts)
      return
    end
  end

  magika.classify(path, opts, function(result)
    if not result then
      return
    end

    if result.confidence < opts.confidence_threshold then
      return
    end

    local filetype = result.filetype
    if not filetype then
      return
    end

    if opts.cache then
      cache.put(key, filetype)
    end

    M.apply(buf, filetype, opts, run_opts)
  end)
end

return M
