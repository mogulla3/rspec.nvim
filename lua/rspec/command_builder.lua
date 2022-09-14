local config = require("rspec.config")

local CommandBuilder = {}

--- Returns list of ancestor paths from current working directory.
--- The return value does not include the root path ("/").
--- Each path does not have a trailing slash.
---
---@return table
---        example: { "/foo/bar/baz", "/foo/bar", "/foo" }
local function get_ancestor_paths()
  local ancestor_paths = {}
  local current_path = vim.fn.getcwd()

  repeat
    table.insert(ancestor_paths, current_path)
    current_path = vim.fn.fnamemodify(current_path, ":h")
  until current_path == "/"

  return ancestor_paths
end

--- Returns whether or not `filename` exists in `path`
---
---@param path string
---       example: "/path/to/my_app"
---@param filename string
---       example: "Gemfile"
---@return boolean
local function has_file(path, filename)
  return vim.fn.filereadable(path .. "/" .. filename) == 1
end

--- Determine the rspec command in the following order of priority.
--- * bin/rspec
--- * bundle exec rspec
--- * rspec
---
--- In addition, the selected rspec command also determines the runtime path.
--- * bin/rspec -> Path where bin/rspec is located. Typically the root directory of the Rails app.
--- * bundle exec rspec -> Path where Gemfile is located.
--- * rspec -> current working directory
---
---@return table: rspec command
---@return string: runtime path to run rspec command
local function determine_rspec_command_and_runtime_path()
  for _, path in pairs(get_ancestor_paths()) do
    if has_file(path, "bin/rspec") then
      return { "bin/rspec" }, path
    elseif has_file(path, "Gemfile") then
      return { "bundle", "exec", "rspec" }, path
    end
  end

  return { "rspec" }, vim.fn.getcwd()
end

--- Build rspec command to be run
---
---@param bufname string: "/path/to/sample_spec.rb"
---@param options table
function CommandBuilder.build(bufname, options)
  local rspec_cmd, runtime_path = determine_rspec_command_and_runtime_path()

  if options.only_nearest then
    local current_line_number = vim.api.nvim_win_get_cursor(0)[1]
    bufname = bufname .. ":" .. current_line_number
  end

  local args = {
    bufname,
    "--format",
    "progress",
    "--format",
    "failures",
    "--out",
    config.last_failed_spec_path,
  }

  if options.only_failures then
    table.insert(args, "--only-failures")
  end

  local command = vim.list_extend(rspec_cmd, args)

  return command, runtime_path
end

return CommandBuilder
