local config = require("rspec.config")
local last_spec_result_win_id = nil

local Viewer = {}

-- Open the floating window that displayed the last spec result
function Viewer.open_last_spec_result_window()
  if last_spec_result_win_id and vim.api.nvim_win_is_valid(last_spec_result_win_id) then
    vim.api.nvim_win_close(last_spec_result_win_id, true)
  end

  local bufnr = vim.api.nvim_create_buf(false, true)

  for _, key in pairs({ "<Esc>", "<CR>", "q" }) do
    vim.api.nvim_buf_set_keymap(bufnr, "n", key, ":close<CR>", { noremap = true, silent = true })
  end

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

  local buf_content = nil
  if vim.g.last_command_stdout then
    buf_content = vim.g.last_command_stdout
  else
    buf_content = { "No specs have been run yet." }
  end

  buf_content = vim.list_extend(buf_content, { "", "* Close the window with the following keys : q, <Esc>, <CR>" })
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, buf_content)

  vim.api.nvim_win_set_option(last_spec_result_win_id, "winhl", "Normal:ErrorFloat")
end

return Viewer
