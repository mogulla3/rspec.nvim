local config = require("rspec.config")
local last_spec_result_win_id = nil

local Viewer = {}

-- Open the floating window that displayed the last spec result
function Viewer.open_last_spec_result_window()
  if last_spec_result_win_id and vim.api.nvim_win_is_valid(last_spec_result_win_id) then
    vim.api.nvim_win_close(last_spec_result_win_id, true)
  end

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

  last_spec_result_win_id = vim.api.nvim_open_win(bufnr, config.focus_on_last_spec_result_window, opts)
  vim.api.nvim_win_set_buf(last_spec_result_win_id, bufnr)
  vim.api.nvim_win_set_option(last_spec_result_win_id, "wrap", true)

  if vim.g.last_command_stdout then
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, vim.g.last_command_stdout)
  else
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { "No specs have been run yet." })
  end

  vim.api.nvim_win_set_option(last_spec_result_win_id, "winhl", "Normal:ErrorFloat")
end

return Viewer
