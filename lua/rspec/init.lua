local command_builder = require("rspec.command_builder")
local config = require("rspec.config")
local runner = require("rspec.runner")
local viewer = require("rspec.viewer")
local jumper = require("rspec.jumper")

local M = {}

--- Save the last executed rspec command and exec path.
---
---@param command string[]
---@param exec_path string
local function save_last_command(command, exec_path)
  vim.g.last_command = {
    command = command,
    exec_path = exec_path,
  }
end

---@param options table
function M.run_current_file(options)
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())

  if not config.allowed_file_format(bufname) then
    vim.notify("[rspec.nvim] Cannot run rspec because of an invalid file name.", vim.log.levels.WARN)
    return
  end

  local cmd_context = command_builder.build(bufname, options or {})

  runner.run_rspec(cmd_context.cmd, cmd_context.exec_path)
  save_last_command(cmd_context.cmd, cmd_context.exec_path)
end

function M.rerun()
  local last_command = vim.g.last_command

  if last_command then
    runner.run_rspec(last_command.command, last_command.exec_path)
  else
    vim.notify("[rspec.nvim] No specs have been run yet.", vim.log.levels.WARN)
  end
end

function M.show_last_result()
  viewer.open_last_spec_result_window()
end

function M.abort()
  runner.abort()
end

function M.jump(options)
  jumper.jump(options)
end

---@param user_config table
function M.setup(user_config)
  user_config = user_config or {}
  config.setup(user_config)

  vim.g.last_command = nil
  vim.g.last_command_stdout = nil
  vim.g.last_command_stderr = nil

  vim.api.nvim_set_hl(0, "RSpecPassed", { bg = "#005f00", fg = "#87d700" })
  vim.api.nvim_set_hl(0, "RSpecFailed", { bg = "#5f0000", fg = "#eb96c4" })
  vim.api.nvim_set_hl(0, "RSpecAborted", { bg = "#5f0000", fg = "#eb96c4" })
  vim.api.nvim_set_hl(0, "RSpecRunning", { bg = "#000000", fg = "#AFC1E9", italic = true })
  vim.api.nvim_set_hl(0, "RSpecRunningBorder", { bg = "#000000", fg = "#AFC1E9" })

  vim.cmd("command! RSpecCurrentFile lua require('rspec').run_current_file()<CR>")
  vim.cmd("command! RSpecNearest lua require('rspec').run_current_file({ only_nearest = true })<CR>")
  vim.cmd("command! RSpecOnlyFailures lua require('rspec').run_current_file({ only_failures = true })<CR>")
  vim.cmd("command! RSpecRerun lua require('rspec').rerun()<CR>")
  vim.cmd("command! RSpecShowLastResult lua require('rspec').show_last_result()<CR>")
  vim.cmd("command! RSpecAbort lua require('rspec').abort()<CR>")
  vim.api.nvim_create_user_command("RSpecJump", function(args)
    jumper.jump({ force = args.bang })
  end, { bang = true })
end

return M
