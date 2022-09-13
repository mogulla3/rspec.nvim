local command_builder = require("rspec.command_builder")
local config = require("rspec.config")
local runner = require("rspec.runner")
local viewer = require("rspec.viewer")

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
    vim.notify("No specs have been run yet.", vim.log.levels.WARN)
  end
end

function M.show_last_spec_result()
  viewer.open_last_spec_result_window()
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
