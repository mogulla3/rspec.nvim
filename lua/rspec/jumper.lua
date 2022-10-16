local Jumper = {}

--- Trace back the parent directory from bufname and infer the root path of the project.
---
--- example:
---   bufname: "/path/to/project/lib/foo/sample.rb"
---   => "/path/to/project"
---
---@param bufname string
---@return string|nil
local function infer_project_root(bufname)
  local paths = vim.fs.find({ ".rspec", "spec" }, { upward = true, path = bufname })

  if vim.tbl_isempty(paths) then
    return nil
  end

  return vim.fs.dirname(paths[1])
end

--- Get a relative path to the project root for bufname
---
--- example:
---   bufname: "/path/to/project/lib/foo/sample.rb"
---   project_root: "/path/to/project"
---   => "lib/foo/sample.rb"
---
---@param bufname string
---@param project_root string
---@return string
local function get_relative_pathname_from_project_root(bufname, project_root)
  local bufpath = vim.split(bufname, "/")
  local project_root_path = vim.split(project_root, "/")
  local relative_path = vim.list_slice(bufpath, #project_root_path + 1)

  return table.concat(relative_path, "/")
end


---@param bufname string
---@param project_root string
---@return string[]
local function infer_spec_paths(bufname, project_root)
  local results = {}
  local relative_pathname = get_relative_pathname_from_project_root(bufname, project_root)

  -- TODO: Consider rspec-rails (e.g. request spec)
  -- TODO: Consider hanami (apps dir)
  local spec_path = nil
  if vim.startswith(relative_pathname, "lib/") then
    spec_path = vim.fn.substitute(relative_pathname, [[^lib/\(.*/\)\?\(.*\).rb$]], "spec/\\1\\2_spec.rb", "")
  elseif vim.startswith(relative_pathname, "app/") then
    spec_path = vim.fn.substitute(relative_pathname, [[^app/\(.*/\)\?\(.*\).rb$]], "spec/\\1\\2_spec.rb", "")
  else
    spec_path = vim.fn.substitute(relative_pathname, [[^\(.*/\)\?\(.*\).rb$]], "spec/\\1\\2_spec.rb", "")
  end

  table.insert(results, project_root .. "/" .. spec_path)

  return results
end

---@param bufname string
---@param project_root string
---@return string[]
local function infer_product_code_paths(bufname, project_root)
  local results = {}
  local relative_pathname = get_relative_pathname_from_project_root(bufname, project_root)
  local product_code_path = vim.fn.substitute(relative_pathname, [[^spec/\(.*/\)\?\(.*\)_spec.rb$]], "\\1\\2.rb", "")

  for _, basedir in pairs({ "/app/", "/lib/", "/" }) do
    if vim.fn.isdirectory(project_root .. basedir) == 1 then
      table.insert(results, project_root .. basedir .. product_code_path)
    end
  end

  return results
end

function Jumper.jump()
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  local basename = vim.fs.basename(bufname)

  if not vim.endswith(basename, ".rb") then
    vim.notify("[rspec.nvim] RSpecJump can only be run on `.rb` files", vim.log.levels.WARN)
    return
  end

  local project_root = infer_project_root(bufname)
  if not project_root then
    vim.notify("[rspec.nvim] RSpecJump cannot infer project root path", vim.log.levels.WARN)
    return
  end

  local inferred_paths = {}
  if vim.endswith(basename, "_spec.rb") then
    inferred_paths = infer_product_code_paths(bufname, project_root)
  else
    inferred_paths = infer_spec_paths(bufname, project_root)
  end

  if vim.tbl_isempty(inferred_paths) then
    vim.notify("[rspec.nvim] RSpecJump cannot infer jump path", vim.log.levels.WARN)
    return
  end

  for _, inferred_path in pairs(inferred_paths) do
    if vim.fn.filereadable(inferred_path) == 1 then
      vim.api.nvim_command("edit " .. inferred_path)
      break
    end
  end
end

return Jumper
