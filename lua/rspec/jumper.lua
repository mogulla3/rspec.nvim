local config = require("rspec.config")

local Jumper = {}

local rails_spec_patterns = {
  default = {
    pattern = [[^app/\(.*/\)\?\(.*\).rb$]],
    replace = "spec/\\1\\2_spec.rb",
  },
  controller = {
    pattern = [[^app/controllers/\(.*/\)\?\(.*\)_controller.rb$]],
    replace = "spec/requests/\\1\\2_spec.rb",
  },
  view = {
    pattern = [[^app/views/\(.*/\)\?\(.*\)$]],
    replace = "spec/views/\\1\\2_spec.rb",
  },
}

local rails_product_code_patterns = {
  default = {
    pattern = [[^spec/\(.*/\)\?\(.*\)_spec.rb$]],
    replace = "app/\\1\\2.rb",
  },
  controller = {
    pattern = [[^spec/requests/\(.*/\)\?\(.*\)_spec.rb$]],
    replace = "app/controllers/\\1\\2_controller.rb",
  },
  view = {
    pattern = [[^spec/views/\(.*/\)\?\(.*\)_spec.rb$]],
    replace = "app/views/\\1\\2",
  },
}

local function get_ignored_dirs()
  return vim.list_extend({ "lib" }, config.ignored_dirs_on_jump)
end

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
  local buf_path = vim.split(bufname, "/")
  local project_root_path = vim.split(project_root, "/")
  local buf_relative_path = vim.list_slice(buf_path, #project_root_path + 1)

  return table.concat(buf_relative_path, "/")
end

---@param subject string
---@param params { pattern: string, replace: string }
---@return string
local function sub(subject, params)
  return vim.fn.substitute(subject, params.pattern, params.replace, "")
end

---@param product_code_relative_path string
---@return string[]
local function infer_rails_spec_paths(product_code_relative_path)
  local dir_entries = vim.split(product_code_relative_path, "/")

  -- TODO: Routing specs, Generator specs
  local results
  if dir_entries[2] == "controllers" then
    results = {
      sub(product_code_relative_path, rails_spec_patterns.controller), -- Request specs
      sub(product_code_relative_path, rails_spec_patterns.default), -- Controller specs
    }
  elseif dir_entries[2] == "views" then
    results = { sub(product_code_relative_path, rails_spec_patterns.view) }
  else
    results = { sub(product_code_relative_path, rails_spec_patterns.default) }
  end

  return results
end

---@param spec_relative_path string
---@return string[]
local function infer_rails_product_code_paths(spec_relative_path)
  local dir_entries = vim.split(spec_relative_path, "/")

  -- TODO: Routing specs, Generator specs
  local results
  if dir_entries[2] == "requests" then
    results = { sub(spec_relative_path, rails_product_code_patterns.controller) }
  elseif dir_entries[2] == "views" then
    results = { sub(spec_relative_path, rails_product_code_patterns.view) }
  else
    results = { sub(spec_relative_path, rails_product_code_patterns.default) }
  end

  return results
end

--- Infer spec paths from the current product code path.
--- This function does not check the existence of the inferred file.
---
---@param bufname string
---@param project_root string
---@return string[]
local function infer_spec_paths(bufname, project_root)
  local current_product_code_relative_path = get_relative_pathname_from_project_root(bufname, project_root)
  local inferred_spec_relative_paths

  if vim.startswith(current_product_code_relative_path, "app/") then
    inferred_spec_relative_paths = infer_rails_spec_paths(current_product_code_relative_path)
  else
    inferred_spec_relative_paths = {
      sub(current_product_code_relative_path, {
        pattern = [[^\(]] .. table.concat(get_ignored_dirs(), [[/\|]]) .. [[/\)\?\(.*/\)\?\(.*\).rb$]],
        replace = "spec/\\2\\3_spec.rb",
      })
    }
  end

  local inferred_spec_paths = {}
  for _, relative_spec_path in pairs(inferred_spec_relative_paths) do
    table.insert(inferred_spec_paths, project_root .. "/" .. relative_spec_path)
  end

  return inferred_spec_paths
end

--- Infer product code paths from the current spec path.
--- This function does not check the existence of the inferred file.
---
---@param bufname string
---@param project_root string
---@return string[]
local function infer_product_code_paths(bufname, project_root)
  local current_spec_relative_path = get_relative_pathname_from_project_root(bufname, project_root)
  local inferred_product_code_relative_paths = {}

  if vim.fn.isdirectory(project_root .. "/app") == 1 then
    vim.list_extend(inferred_product_code_relative_paths, infer_rails_product_code_paths(current_spec_relative_path))
  end

  for _, ignored_dir in ipairs(get_ignored_dirs()) do
    table.insert(inferred_product_code_relative_paths, sub(current_spec_relative_path, { pattern = [[^spec/\(.*/\)\?\(.*\)_spec.rb$]], replace = ignored_dir .. "/" .. "\\1\\2.rb" }))
  end

  table.insert(inferred_product_code_relative_paths, sub(current_spec_relative_path, { pattern = [[^spec/\(.*/\)\?\(.*\)_spec.rb$]], replace = "\\1\\2.rb" }))

  local inferred_product_code_paths = {}
  for _, relative_product_code_path in pairs(inferred_product_code_relative_paths) do
    table.insert(inferred_product_code_paths, project_root .. "/" .. relative_product_code_path)
  end

  return inferred_product_code_paths
end

--- Jump to the path passed in the argument
---
---@param path string
local function jump_to_file(path)
  vim.api.nvim_command(config.jump_command .. " " .. path)
end

--- Jump to the path passed in the argument
--- If the directory does not exist, create it.
---
---@param path string
local function force_jump_to_file(path)
  if vim.fn.filereadable(path) ~= 1 then
    vim.fn.mkdir(vim.fs.dirname(path), "p")
  end

  jump_to_file(path)
end

--- Jump between specs and product code.
---
--- If the current buffer is a product code, it jumps to the related specs.
--- If the current buffer is a specs, it jumps to the related product code.
---
--- The file to jump to is inferred based on the general directory structure and general file naming conventions.
--- - Example1. lib/foo/bar/baz.rb -> spec/foo/bar/baz_spec.rb
--- - Example2. app/models/user.rb -> spec/models/user_spec.rb
---
--- The inferred jump destination files have a priority order.
--- The files are searched in order of priority and the first file found is jumped to.
---
--- If the force option is enabled, create the inferred file if it does not exist.
---
---@param options table
function Jumper.jump(options)
  local opts = options or {}
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  if not vim.endswith(bufname, ".rb") then
    vim.notify("[rspec.nvim] RSpecJump can only be run on `.rb` files", vim.log.levels.ERROR)
    return
  end

  local project_root = infer_project_root(bufname)
  if not project_root then
    vim.notify("[rspec.nvim] RSpecJump cannot infer project root path", vim.log.levels.ERROR)
    return
  end

  local inferred_paths = {}
  if vim.endswith(bufname, "_spec.rb") then
    inferred_paths = infer_product_code_paths(bufname, project_root)
  else
    inferred_paths = infer_spec_paths(bufname, project_root)
  end

  if vim.tbl_isempty(inferred_paths) then
    vim.notify("[rspec.nvim] RSpecJump cannot infer jump path", vim.log.levels.ERROR)
    return
  end

  if opts.force then
    local selected_path

    if vim.tbl_count(inferred_paths) > 1 then
      local inputlist_items = { "Choose the path you want to jump." }
      for i, inferred_path in pairs(inferred_paths) do
        table.insert(inputlist_items, i .. ": " .. inferred_path)
      end

      local selected_num = vim.fn.inputlist(inputlist_items)
      selected_path = inferred_paths[selected_num]

      -- If the user presses `Escape` or `q`, 0 is passed.
      if selected_num == 0 then
        return
      elseif not selected_path then
        vim.notify("[rspec.nvim] Invalid number '" .. selected_num .. "' is selected", vim.log.levels.ERROR)
        return
      end
    else
      selected_path = inferred_paths[1]
    end

    force_jump_to_file(selected_path)
  else
    local is_file_found = false

    for _, inferred_path in pairs(inferred_paths) do
      if vim.fn.filereadable(inferred_path) == 1 then
        jump_to_file(inferred_path)
        is_file_found = true
        break
      end
    end

    if not is_file_found then
      vim.notify(
        "[rspec.nvim] Not found all of the following files:\n" .. table.concat(inferred_paths, "\n"),
        vim.log.levels.ERROR
      )
    end
  end
end

return Jumper
