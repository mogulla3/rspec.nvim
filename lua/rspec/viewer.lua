local config = require("rspec.config")
local last_spec_result_win_id = nil

local Viewer = {}

---@return number
local function create_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Key mappings for easy window closing
  for _, key in pairs({ "<Esc>", "<CR>", "q" }) do
    vim.api.nvim_buf_set_keymap(bufnr, "n", key, "", {
      noremap = true,
      silent = true,
      callback = function()
        vim.api.nvim_win_close(last_spec_result_win_id, true)
        last_spec_result_win_id = nil
      end
    })
  end

  return bufnr
end

---@param bufnr number
---@return number
local function open_window(bufnr)
  -- margin: 5 10
  local win_opts = {
    relative = "editor",
    row = 5,
    col = 10,
    width = vim.fn.winwidth(0) - 20,
    height = vim.fn.winheight(0) - 10,
    style = "minimal",
    border = "rounded",
  }

  local win_id = vim.api.nvim_open_win(bufnr, config.focus_on_last_spec_result_window, win_opts)
  vim.api.nvim_win_set_option(win_id, "wrap", true)
  vim.api.nvim_win_set_option(win_id, "winhl", "Normal:ErrorFloat")
  vim.api.nvim_win_set_buf(win_id, bufnr)

  return win_id
end

---@return string
local function build_buffer_content()
  local buf_content = nil

  if vim.g.last_command_stdout then
    buf_content = vim.g.last_command_stdout
  else
    buf_content = { "No specs have been run yet." }
  end

  buf_content = vim.list_extend(buf_content, { "", "* Close the window with the following keys : q, <Esc>, <CR>" })
  buf_content = table.concat(buf_content, "\r\n")

  return buf_content
end

-- Open the floating window that displayed the last spec result
function Viewer.open_last_spec_result_window()
  -- Prevent multiple window openings
  if last_spec_result_win_id and vim.api.nvim_win_is_valid(last_spec_result_win_id) then
    vim.api.nvim_win_close(last_spec_result_win_id, true)
  end

  local bufnr = create_buffer()
  last_spec_result_win_id = open_window(bufnr)
  local chan = vim.api.nvim_open_term(bufnr, {})
  local buf_content = build_buffer_content()
  vim.api.nvim_chan_send(chan, buf_content)

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = bufnr,
    callback = function()
      vim.api.nvim_buf_delete(bufnr, { force = true })
      vim.fn.chanclose(chan)
    end
  })
end

return Viewer
