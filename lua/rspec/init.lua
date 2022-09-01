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
  for _, path in pairs(get_ancestor_paths()) do
    if has_file(path, "bin/rspec") then
      return "bin/rspec", path
    elseif has_file(path, "Gemfile") then
      return "bundle exec rspec", path
    end
  end

  return "rspec", vim.fn.getcwd()
end

local function save_last_command(cmd, exec_path)
  vim.g.last_command = {
    cmd = cmd,
    exec_path = exec_path,
  }
end

function M.run_current_spec_file()
  if vim.fn.bufexists(term) > 0 then
    vim.api.nvim_buf_delete(term, { force = true })
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local rspec_cmd, cmd_exec_path = determine_rspec_cmd()
  local cmd = rspec_cmd .. " " .. bufname

  vim.cmd("botright vsplit new")
  vim.fn.termopen(cmd, { cwd = cmd_exec_path })
  vim.cmd("startinsert")

  save_last_command(cmd, cmd_exec_path)

  term = vim.api.nvim_get_current_buf()
end

-- TODO: Fix duplicated codes..
function M.run_nearest_spec()
  if vim.fn.bufexists(term) > 0 then
    vim.api.nvim_buf_delete(term, { force = true })
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local rspec_cmd, cmd_exec_path = determine_rspec_cmd()
  local current_line_number = vim.api.nvim_win_get_cursor(0)[1]
  local cmd = rspec_cmd .. " " .. bufname .. ":" .. current_line_number

  vim.cmd("botright vsplit new")
  vim.fn.termopen(cmd, { cwd = cmd_exec_path })
  vim.cmd("startinsert")

  save_last_command(cmd, cmd_exec_path)

  term = vim.api.nvim_get_current_buf()
end

-- TODO: Fix duplicated codes..
function M.run_last_spec()
  local last_command = vim.g.last_command

  if last_command then
    vim.cmd("botright vsplit new")
    vim.fn.termopen(last_command.cmd, { cwd = last_command.exec_path })
    vim.cmd("startinsert")
    term = vim.api.nvim_get_current_buf()
  else
    vim.notify("last command not found", vim.log.levels.WARN)
  end
end

function M.setup()
  -- For the purpose of storing the last rspec command
  vim.g.last_command = nil

  vim.cmd "command! RunCurrentSpecFile lua require('rspec').run_current_spec_file()<CR>"
  vim.cmd "command! RunNearestSpec lua require('rspec').run_nearest_spec()<CR>"
  vim.cmd "command! RunLastSpec lua require('rspec').run_last_spec()<CR>"
end

return M
