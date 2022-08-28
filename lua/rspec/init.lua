local M = {}
local term = nil

function M.run_file()
  if vim.fn.bufexists(term) > 0 then
    vim.api.nvim_buf_delete(term, { force = true })
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  vim.cmd("botright vsplit new")
  local cmd = 'bundle exec rspec ' .. bufname

  vim.fn.termopen(cmd)
  vim.cmd("startinsert")
  term = vim.api.nvim_get_current_buf()
end

function M.setup()
  vim.cmd "command! RSpecFile lua require('rspec').run_file()<CR>"
end

return M
