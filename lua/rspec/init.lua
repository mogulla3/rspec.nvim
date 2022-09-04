local utils = require "rspec.utils"
local M = {}
local term = nil
local last_failed_test_path = vim.fn.stdpath("data") .. "/" .. "rspec_last_failed_examples"

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
---@return string
---@return string
local function determine_rspec_cmd_and_runtime_path()
  for _, path in pairs(utils.get_ancestor_paths()) do
    if utils.has_file(path, "bin/rspec") then
      return "bin/rspec", path
    elseif utils.has_file(path, "Gemfile") then
      return "bundle exec rspec", path
    end
  end

  return "rspec", vim.fn.getcwd()
end

--- Save the last executed rspec command and runtime info.
---
---@param command string
---@param runtime_path string
local function save_last_command(command, runtime_path)
  vim.g.last_command = {
    command = command,
    runtime_path = runtime_path,
  }
end

--- TODO: Change to a better method name OR split the method
---
---@param opts table
local function build_commands(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local rspec_cmd, runtime_path = determine_rspec_cmd_and_runtime_path()

  if opts.only_nearest then
    local current_line_number = vim.api.nvim_win_get_cursor(0)[1]
    bufname = bufname .. ":" .. current_line_number
  end

  local command = table.concat({
    rspec_cmd,
    bufname,
    '--format',
    'documentation',
    '--format',
    'failures',
    '--out',
    last_failed_test_path,
  }, ' ')

  return command, runtime_path
end

--- Run rspec command
---
---@param command string
---@param runtime_path string
local function run_rspec(command, runtime_path)
  vim.api.nvim_command("cclose")

  -- TODO: Allow customizable size and position
  vim.cmd("botright vsplit new")

  -- To close the terminal by pressing any key
  vim.cmd("startinsert")

  vim.fn.termopen(command, {
    cwd = runtime_path,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      vim.g.last_command_stdout = data
    end,
    on_stderr = function(_, data, _)
      vim.g.last_command_stderr = data
    end,
    -- see: help :on_exit
    on_exit = function(_, exit_code, _)
      -- TODO: failしたexampleがあった場合、元のwindowでquickfixを開きたいのですぐquit
      -- もっと良いやり方がありそう
      vim.api.nvim_command("quit")

      if exit_code == 0 then
        vim.api.nvim_echo({{'spec passed', 'RSpecPassed'}}, true, {})
      else
        vim.api.nvim_echo({{'spec failed', 'RSpecFailed'}}, true, {})

        -- In the case of errors prior to running RSpec, such as SyntaxError, nothing is written to the file.
        -- Therefore, the file size is used for verification.
        if vim.fn.getfsize(last_failed_test_path) > 0 then
          local failed_examples = vim.fn.readfile(last_failed_test_path)
          failed_examples = vim.list_extend({ "Failed examples are as follows." }, failed_examples)
          vim.fn.setqflist({}, "r", { efm = "%f:%l:%m", lines = failed_examples })
          vim.api.nvim_command("copen")
        end
      end
    end,
  })
end

function M.run_current_spec_file()
  if vim.fn.bufexists(term) > 0 then
    vim.api.nvim_buf_delete(term, { force = true })
  end

  local command, runtime_path = build_commands({})
  run_rspec(command, runtime_path)
  save_last_command(command, runtime_path)

  term = vim.api.nvim_get_current_buf()
end

function M.run_nearest_spec()
  if vim.fn.bufexists(term) > 0 then
    vim.api.nvim_buf_delete(term, { force = true })
  end

  local command, runtime_path = build_commands({ only_nearest = true })
  run_rspec(command, runtime_path)
  save_last_command(command, runtime_path)

  term = vim.api.nvim_get_current_buf()
end

function M.run_last_spec()
  local last_command = vim.g.last_command

  if last_command then
    run_rspec(last_command.command, last_command.runtime_path)
    term = vim.api.nvim_get_current_buf()
  else
    vim.notify("last command not found", vim.log.levels.WARN)
  end
end

function M.setup()
  -- For the purpose of storing the last rspec command
  vim.g.last_command = nil
  vim.g.last_command_stdout = nil
  vim.g.last_command_stderr = nil

  vim.api.nvim_set_hl(0, 'RSpecPassed', { default = true, link = 'DiffAdd' })
  vim.api.nvim_set_hl(0, 'RSpecFailed', { default = true, link = 'DiffDelete' })

  vim.cmd "command! RunCurrentSpecFile lua require('rspec').run_current_spec_file()<CR>"
  vim.cmd "command! RunNearestSpec lua require('rspec').run_nearest_spec()<CR>"
  vim.cmd "command! RunLastSpec lua require('rspec').run_last_spec()<CR>"
end

return M
