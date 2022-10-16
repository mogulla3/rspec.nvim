-- local config = require("rspec.config")

local Jumper = {}

--- Trace back the parent directory from bufname and infer the root path of the project.
---
---@param bufname string
---@return table|nil # example: { "path", "to", "project" }
local function infer_project_root_path(bufname)
  local paths = vim.fs.find({ ".rspec", "spec" }, { upward = true, path = bufname })

  if vim.tbl_isempty(paths) then
    return nil
  end

  return vim.split(vim.fs.dirname(paths[1]), "/")
end

--- Get a relative path to the project root for bufname
--- example:
---   project_root: /path/to/project
---   bufname: /path/to/project/lib/foo/sample.rb
---   => { "lib", "foo", "sample.rb" }
---
---@param bufname string
---@return table|nil
local function get_relative_path_from_project_root(bufname)
  local project_root_path = infer_project_root_path(bufname)
  if not project_root_path then
    return nil
  end

  local bufpath = vim.split(bufname, "/")

  return vim.list_slice(bufpath, #project_root_path + 1)
end

local function infer_spec_paths(bufname)
  local results = {}
  local relative_path = get_relative_path_from_project_root(bufname)
  local relative_pathname = table.concat(relative_path, "/")

  -- TODO: Consider rspec-rails (e.g. request spec)
  -- TODO: Consider hanami (apps dir)
  if vim.startswith(relative_pathname, "lib/") then
    spec_path = vim.fn.substitute(relative_pathname, [[^lib/\(.*/\)\?\(.*\).rb$]], "spec/\\1\\2_spec.rb", "")
  elseif vim.startswith(relative_pathname, "app/") then
    spec_path = vim.fn.substitute(relative_pathname, [[^app/\(.*/\)\?\(.*\).rb$]], "spec/\\1\\2_spec.rb", "")
  else
    spec_path = vim.fn.substitute(relative_pathname, [[^\(.*/\)\?\(.*\).rb$]], "spec/\\1\\2_spec.rb", "")
  end

  table.insert(results, spec_path)

  return results
end

local function infer_product_code_paths(bufname)
  local project_root
  for dir in vim.fs.parents(bufname) do
    if vim.endswith(dir, "/spec") then
      project_root = vim.fs.dirname(dir)
      break
    end
  end

  local buf_path = vim.split(bufname, "/")
  local project_root_path = vim.split(project_root, "/")
  local buf_path_from_project_root = vim.list_slice(buf_path, #project_root_path + 1)

  local results = {}
  for _, path in pairs({ "lib", "app" }) do
    local product_code_path = vim.deepcopy(buf_path_from_project_root)

    product_code_path[1] = path
    product_code_path[#product_code_path] = string.gsub(product_code_path[#product_code_path], "^(.*)_spec.rb$", "%1.rb", 1)

    local x = vim.list_extend(vim.deepcopy(project_root_path), product_code_path)

    table.insert(results, table.concat(x, "/"))
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

  local inferred_paths = {}
  if vim.endswith(basename, "_spec.rb") then
    inferred_paths = infer_product_code_paths(bufname)
  else
    inferred_paths = infer_spec_paths(bufname)
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
