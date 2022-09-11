local utils = require("rspec.utils")
local last_failed_test_path = vim.fn.stdpath("data") .. "/" .. "rspec_last_failed_examples"
local M = {}

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
---@return string: rspec command
---@return string: runtime path to run rspec command
local function determine_rspec_command_and_runtime_path()
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
---@param command table
---@param runtime_path string
local function save_last_command(command, runtime_path)
  vim.g.last_command = {
    command = command,
    runtime_path = runtime_path,
  }
end

--- TODO: Change to a better method name OR split the method
---
---@param bufname string: "/path/to/sample_spec.rb"
---@param options table
local function build_commands(bufname, options)
  local rspec_cmd, runtime_path = determine_rspec_command_and_runtime_path()
  local option_args = {
    '--format',
    'progress',
    '--format',
    'failures',
    '--out',
    last_failed_test_path,
  }

  if options.only_nearest then
    local current_line_number = vim.api.nvim_win_get_cursor(0)[1]
    bufname = bufname .. ":" .. current_line_number
  end

  if options.only_failures then
    table.insert(option_args, "--only-failures")
  end

  local command = vim.list_extend({ rspec_cmd, bufname }, option_args)

  return command, runtime_path
end

--- Open a window showing rspec progress
---
---@return number: window id
local function open_progress_window()
  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_width = vim.fn.winwidth(0)
  local win_height = vim.fn.winheight(0)

  -- Render floating window on right bottom
  local opts = {
    relative = "win",
    anchor = "SE",
    focusable = false,
    row = win_height - 2,
    col = win_width - 4,
    width = 16, -- fit to message length
    height = 1,
    style = "minimal",
    border = "rounded",
  }

  local win_id = vim.api.nvim_open_win(bufnr, false, opts)
  vim.api.nvim_win_set_buf(win_id, bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { "Running RSpec..." })
  vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:ErrorFloat')

  return win_id
end

--- Run rspec command
---
---@param command table
---@param runtime_path string
---@return number
local function run_rspec(command, runtime_path)
  vim.api.nvim_command("cclose")

  local progress_win_id = open_progress_window()

  utils.log(vim.inspect(command))
  utils.log(vim.inspect(runtime_path))

  -- job_id
  --  0 -> invalid argument
  -- -1 -> cmd is not executable
  local job_id = vim.fn.jobstart(command, {
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
      vim.api.nvim_win_close(progress_win_id, true)

      if exit_code == 0 then
        vim.api.nvim_echo({{'spec passed', 'RSpecPassed'}}, true, {})
      else
        -- TODO: Make the message more detailed but in an amount that fits on 1 line.
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

  if job_id < 1 then
    vim.notify(string.format("command failed(%i)", job_id), vim.log.levels.ERROR)
  end

  return job_id
end

---@param options table
function M.run_current_spec(options)
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())

  -- TODO: Since rspec has no restrictions on file names to be tested,
  --       the file formats that are allowed to be executed can be changed in the settings.
  -- see: https://relishapp.com/rspec/rspec-core/v/3-11/docs/spec-files/arbitrary-file-suffix
  if not vim.endswith(bufname, '_spec.rb') then
    vim.notify("Cannot run rspec because of an invalid file name.", vim.log.levels.WARN)
    return
  end

  local command, runtime_path = build_commands(bufname, options or {})

  run_rspec(command, runtime_path)
  save_last_command(command, runtime_path)
end

function M.run_last_spec()
  local last_command = vim.g.last_command

  if last_command then
    run_rspec(last_command.command, last_command.runtime_path)
  else
    vim.notify("last command not found", vim.log.levels.WARN)
  end
end

-- TODO: Consider already opened float window
function M.show_last_spec_result()
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- margin: 5 10
  local win_width = vim.fn.winwidth(0)
  local win_height = vim.fn.winheight(0)

  local opts = {
    relative = "editor",
    row = 5,
    col = 10,
    width = win_width - 20,
    height = win_height - 10,
    style = "minimal",
    border = "rounded",
  }

  local win_id = vim.api.nvim_open_win(bufnr, true, opts)
  vim.api.nvim_win_set_buf(win_id, bufnr)
  vim.api.nvim_win_set_option(win_id, "wrap", true)

  if vim.g.last_command_stdout then
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, vim.g.last_command_stdout)
  else
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { "No specs have been run yet in this session." })
  end

  vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:ErrorFloat')
end

function M.setup()
  vim.g.last_command = nil
  vim.g.last_command_stdout = nil
  vim.g.last_command_stderr = nil

  vim.api.nvim_set_hl(0, 'RSpecPassed', { default = true, link = 'DiffAdd' })
  vim.api.nvim_set_hl(0, 'RSpecFailed', { default = true, link = 'DiffDelete' })

  vim.cmd "command! RunCurrentSpec lua require('rspec').run_current_spec()<CR>"
  vim.cmd "command! RunNearestSpec lua require('rspec').run_current_spec({ only_nearest = true })<CR>"
  vim.cmd "command! RunFailedSpec lua require('rspec').run_current_spec({ only_failures = true })<CR>"
  vim.cmd "command! RunLastSpec lua require('rspec').run_last_spec()<CR>"
  vim.cmd "command! ShowLastSpecResult lua require('rspec').show_last_spec_result()<CR>"
end

return M
