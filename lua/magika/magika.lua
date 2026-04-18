local M = {}

local label_overrides = {
  ace = false,
  ai = "postscr",
  appleplist = "xml",
  asp = "aspvbs",
  batch = "dosbatch",
  bazel = "bzl",
  coff = false,
  csproj = "xml",
  eml = "mail",
  erb = "eruby",
  gemfile = "ruby",
  gemspec = "ruby",
  gitmodules = "gitconfig",
  gradle = "groovy",
  hlp = false,
  ignorefile = "gitignore",
  ini = "dosini",
  internetshortcut = "urlshortcut",
  ipynb = "json",
  javabytecode = false,
  jsonl = "json",
  latex = "tex",
  m3u = "hlsplaylist",
  makefile = "make",
  objectivec = "objc",
  pdb = false,
  pickle = false,
  postscript = "postscr",
  powershell = "ps1",
  proteindb = false,
  pytorch = false,
  rdf = "xml",
  shell = "sh",
  sum = false,
  textproto = "pbtxt",
  txt = "text",
  vba = "vb",
  vcxproj = "xml",
  winregistry = "registry",
  xar = false,
}

local available_filetypes

local function get_available_filetypes()
  if not available_filetypes then
    available_filetypes = {}
    for _, filetype in ipairs(vim.fn.getcompletion("", "filetype")) do
      available_filetypes[filetype] = true
    end
  end

  return available_filetypes
end

local function decode_json(stdout)
  if not stdout or stdout == "" then
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok then
    return nil
  end

  return decoded
end

local function first_result(decoded)
  if type(decoded) ~= "table" then
    return nil
  end

  if decoded[1] ~= nil then
    return decoded[1]
  end

  return decoded
end

local function normalize(decoded)
  local item = first_result(decoded)
  if type(item) ~= "table" then
    return nil
  end

  local result = item.result
  if type(result) ~= "table" or result.status ~= "ok" then
    return nil
  end

  local value = result.value
  if type(value) ~= "table" then
    return nil
  end

  local output = value.output
  if type(output) ~= "table" then
    output = value
  end

  local label = output.label
  local score = value.score or output.score
  if type(label) ~= "string" or label == "" or type(score) ~= "number" then
    return nil
  end

  local extensions = {}
  if type(output.extensions) == "table" then
    for _, extension in ipairs(output.extensions) do
      if type(extension) == "string" and extension ~= "" then
        extensions[#extensions + 1] = extension
      end
    end
  end

  return {
    label = label,
    confidence = score,
    extensions = extensions,
    description = output.description,
    mime_type = output.mime_type,
  }
end

local function is_known_filetype(filetype)
  return type(filetype) == "string" and filetype ~= "" and get_available_filetypes()[filetype] == true
end

local function resolve_filetype(result)
  if type(result) ~= "table" then
    return nil
  end

  local override = label_overrides[result.label]
  if override ~= nil then
    return override or nil
  end

  local label = result.label
  if is_known_filetype(label) then
    return label
  end

  for _, extension in ipairs(result.extensions or {}) do
    local filetype = vim.filetype.match({ filename = "x." .. extension })
    if type(filetype) == "string" and filetype ~= "" then
      return filetype
    end
  end

  return nil
end

function M.classify(path, opts, cb)
  local cmd = vim.deepcopy(opts.magika_cmd or {})
  cmd[#cmd + 1] = path

  vim.system(cmd, {
    text = true,
    timeout = opts.timeout_ms,
  }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        cb(nil)
        return
      end

      local result = normalize(decode_json(obj.stdout))
      if result then
        result.filetype = resolve_filetype(result)
      end
      cb(result)
    end)
  end)
end

return M
