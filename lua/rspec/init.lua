local config = require("rspec.config")
local command_builder = require("rspec.command_builder")
local runner = require("rspec.runner")

local M = {}

--- Save the last executed rspec command and runtime path.
---
---@param command table
---@param runtime_path string
local function save_last_command(command, runtime_path)
  vim.g.last_command = {
    command = command,
    runtime_path = runtime_path,
  }
end

---@param options table
function M.run_current_spec(options)
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())

  if not config.allowed_file_format(bufname) then
    vim.notify("Cannot run rspec because of an invalid file name.", vim.log.levels.WARN)
    return
  end

  local command, runtime_path = command_builder.build(bufname, options or {})

  runner.run_rspec(command, runtime_path)
  save_last_command(command, runtime_path)
end

function M.run_last_spec()
  local last_command = vim.g.last_command

  if last_command then
    runner.run_rspec(last_command.command, last_command.runtime_path)
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

  local win_id = vim.api.nvim_open_win(bufnr, config.focus_on_last_spec_result_window, opts)
  vim.api.nvim_win_set_buf(win_id, bufnr)
  vim.api.nvim_win_set_option(win_id, "wrap", true)

  if vim.g.last_command_stdout then
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, vim.g.last_command_stdout)
  else
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { "No specs have been run yet in this session." })
  end

  vim.api.nvim_win_set_option(win_id, "winhl", "Normal:ErrorFloat")
end

---@param user_config table
function M.setup(user_config)
  user_config = user_config or {}
  config.setup(user_config)

  vim.g.last_command = nil
  vim.g.last_command_stdout = nil
  vim.g.last_command_stderr = nil

  vim.api.nvim_set_hl(0, "RSpecPassed", { default = true, link = "DiffAdd" })
  vim.api.nvim_set_hl(0, "RSpecFailed", { default = true, link = "DiffDelete" })

  vim.cmd("command! RunCurrentSpec lua require('rspec').run_current_spec()<CR>")
  vim.cmd("command! RunNearestSpec lua require('rspec').run_current_spec({ only_nearest = true })<CR>")
  vim.cmd("command! RunFailedSpec lua require('rspec').run_current_spec({ only_failures = true })<CR>")
  vim.cmd("command! RunLastSpec lua require('rspec').run_last_spec()<CR>")
  vim.cmd("command! ShowLastSpecResult lua require('rspec').show_last_spec_result()<CR>")
end

return M
