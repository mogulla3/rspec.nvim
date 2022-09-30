local config = require("rspec.config")
local default_formatter = "progress"
local allowed_formatters = { "progress", "p", "documentation", "d" }

local CommandBuilder = {}

--- Returns list of ancestor paths from current working directory.
--- The return value does not include the root path ("/").
--- Each path does not have a trailing slash.
---
---@return string[] # example: { "/foo/bar/baz", "/foo/bar", "/foo" }
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
---@param path string # example: "/path/to/my_app"
---@param filename string # example: "Gemfile"
---@return boolean
local function has_file(path, filename)
  return vim.fn.filereadable(path .. "/" .. filename) == 1
end

--- Determine the rspec command in the following order of priority.
--- * bin/rspec
--- * bundle exec rspec
--- * rspec
---
--- In addition, the selected rspec command also determines the exec path.
--- * bin/rspec -> Path where bin/rspec is located. Typically the root directory of the Rails app.
--- * bundle exec rspec -> Path where Gemfile is located.
--- * rspec -> current working directory
---
---@return { bin_cmd: string[], exec_path: string }
local function determine_rspec_context()
  local bin_cmd = { "rspec" }
  local exec_path = vim.fn.getcwd()

  for _, path in pairs(get_ancestor_paths()) do
    if has_file(path, "bin/rspec") then
      bin_cmd = { "bin/rspec" }
      exec_path = path
    elseif has_file(path, "Gemfile") then
      bin_cmd = { "bundle", "exec", "rspec" }
      exec_path = path
    end
  end

  return { bin_cmd = bin_cmd, exec_path = exec_path }
end

--- Determine rspec formatter.
--
---@return string
local function determine_rspec_formatter()
  return vim.tbl_contains(allowed_formatters, config.formatter) and config.formatter or default_formatter
end

--- Build rspec command to be run
---
---@param bufname string # example: "/path/to/sample_spec.rb"
---@param options table
---@return { cmd: string[], exec_path: string }
function CommandBuilder.build(bufname, options)
  local rspec_context = determine_rspec_context()
  local formatter = determine_rspec_formatter()

  if options.only_nearest then
    local current_line_number = vim.api.nvim_win_get_cursor(0)[1]
    bufname = bufname .. ":" .. current_line_number
  end

  local rspec_args = {
    bufname,
    "--force-color",
    "--format",
    formatter,
    "--format",
    "json",
    "--out",
    config.last_result_path,
    "--format",
    "failures",
    "--out",
    config.last_failed_result_path,
  }

  if options.only_failures then
    table.insert(rspec_args, "--only-failures")
  end

  return {
    cmd = vim.list_extend(rspec_context.bin_cmd, rspec_args),
    exec_path = rspec_context.exec_path,
  }
end

return CommandBuilder
