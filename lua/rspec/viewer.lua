local config = require("rspec.config")

local closing_keys = { "q", "<Esc>", "<CR>" }
local last_spec_result_win_id = nil

local Viewer = {}

---@return number # number of created buffer
local function create_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Set key mappings for easy window closing
  for _, closing_key in pairs(closing_keys) do
    vim.api.nvim_buf_set_keymap(bufnr, "n", closing_key, "", {
      noremap = true,
      silent = true,
      callback = function()
        vim.api.nvim_win_close(last_spec_result_win_id, true)
        last_spec_result_win_id = nil
      end,
    })
  end

  return bufnr
end

---@return { win_id: number, bufnr: number }
local function create_window()
  local bufnr = create_buffer()

  -- margin: 5 10
  local opts = {
    relative = "editor",
    row = 5,
    col = 10,
    width = vim.fn.winwidth(0) - 20,
    height = vim.fn.winheight(0) - 10,
    style = "minimal",
    border = "rounded",
  }

  local win_id = vim.api.nvim_open_win(bufnr, config.focus_on_last_spec_result_window, opts)
  vim.api.nvim_set_option_value("wrap", true, { win = win_id })
  vim.api.nvim_set_option_value("winhl", "Normal:ErrorFloat", { win = win_id })
  vim.api.nvim_win_set_buf(win_id, bufnr)

  return { win_id = win_id, bufnr = bufnr }
end

--- Build the last test result output by RSpec.
--- The format is designed to be output to a terminal.
---
---@return string
local function build_buffer_content()
  local buf_content = nil

  if vim.g.last_command_stdout then
    buf_content = vim.g.last_command_stdout
  else
    buf_content = { "No specs have been run yet." }
  end

  buf_content = vim.list_extend(
    buf_content,
    { "", "* Close the window with the following keys : " .. table.concat(closing_keys, ", ") }
  )
  buf_content = table.concat(buf_content, "\r\n")

  return buf_content
end

-- Open the floating window that displayed the last spec result
function Viewer.open_last_spec_result_window()
  -- Prevent multiple window openings
  if last_spec_result_win_id and vim.api.nvim_win_is_valid(last_spec_result_win_id) then
    vim.api.nvim_win_close(last_spec_result_win_id, true)
  end

  local window = create_window()
  local bufnr = window.bufnr
  last_spec_result_win_id = window.win_id

  local chan_id = vim.api.nvim_open_term(bufnr, {})
  local buf_content = build_buffer_content()
  vim.api.nvim_chan_send(chan_id, buf_content)

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = bufnr,
    callback = function()
      vim.api.nvim_buf_delete(bufnr, { force = true })
      vim.fn.chanclose(chan_id)
    end,
  })
end

return Viewer
