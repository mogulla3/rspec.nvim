local M = {}
local term = nil

-- Returns list of ancestor paths from current working directory.
-- The return value does not include the root path ("/").
-- Each path does not have a trailing slash.
--
-- @example { "/foo/bar/baz", "/foo/bar", "/foo" }
-- @return a table of paths
local function get_ancestor_paths()
  local ancestor_paths = {}
  local current_path = vim.fn.getcwd()

  repeat
    table.insert(ancestor_paths, current_path)
    current_path = vim.fn.fnamemodify(current_path, ':h')
  until current_path == '/'

  return ancestor_paths
end

-- Returns whether or not `filename` exists in `path`
--
-- @param path
-- @param filename
-- @return boolean
local function has_file(path, filename)
  return vim.fn.filereadable(path .. "/" .. filename) == 1
end

-- Determine the rspec command in the following order of priority.
-- * bin/rspec
-- * bundle exec rspec
-- * rspec
--
-- In addition, the selected rspec command also determines the runtime path.
-- * bin/rspec -> Path where bin/rspec is located. Typically the root directory of the Rails app.
-- * bundle exec rspec -> Path where Gemfile is located.
-- * rspec -> current working directory
--
-- @return cmd
-- @return runtime_path
local function determine_rspec_cmd()
  local cmd = "rspec"
  local cmd_exec_path = vim.fn.getcwd()

  for _, path in pairs(get_ancestor_paths()) do
    if has_file(path, "bin/rspec") then
      cmd = "bin/rspec"
      cmd_exec_path = path
    elseif has_file(path, "Gemfile") then
      cmd = "bundle exec rspec"
      cmd_exec_path = path
    end
  end

  return cmd, cmd_exec_path
end

function M.run_file()
  if vim.fn.bufexists(term) > 0 then
    vim.api.nvim_buf_delete(term, { force = true })
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local rspec_cmd, cmd_exec_path = determine_rspec_cmd()

  vim.cmd("botright vsplit new")
  local cmd = rspec_cmd .. " " .. bufname

  vim.notify("cmd = " .. cmd, vim.log.levels.DEBUG)
  vim.notify("cmd_exec_path = " .. cmd_exec_path, vim.log.levels.DEBUG)

  vim.fn.termopen(cmd, { cwd = cmd_exec_path })
  vim.cmd("startinsert")
  term = vim.api.nvim_get_current_buf()
end

function M.setup()
  vim.cmd "command! RSpecFile lua require('rspec').run_file()<CR>"
end

return M
