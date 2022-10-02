-- local config = require("rspec.config")

local Jumper = {}

local function infer_spec_paths(bufname)
  local project_root
  for dir in vim.fs.parents(bufname) do
    if vim.endswith(dir, "/lib") or vim.endswith(dir, "/app") then
      project_root = vim.fs.dirname(dir)
      break
    end
  end

  local bufpath = vim.split(bufname, "/")
  local project_root_path = vim.split(project_root, "/")
  local bufpath_from_project_root = vim.list_slice(bufpath, #project_root_path + 1)

  -- TODO: Consider more patterns
  bufpath_from_project_root[1] = "spec"
  bufpath_from_project_root[#bufpath_from_project_root] = string.gsub(bufpath_from_project_root[#bufpath_from_project_root], "^(.*)%.rb$", "%1_spec.rb", 1)

  local results = {}

  local spec_path = vim.list_extend(project_root_path, bufpath_from_project_root)
  table.insert(results, table.concat(spec_path, "/"))

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

  for _, inferred_path in pairs(inferred_paths) do
    if vim.fn.filereadable(inferred_path) == 1 then
      vim.api.nvim_command("edit " .. inferred_path)
      break
    end
  end
end

return Jumper
