local M = {}

--- Returns list of ancestor paths from current working directory.
--- The return value does not include the root path ("/").
--- Each path does not have a trailing slash.
---
---@return table
---        example: { "/foo/bar/baz", "/foo/bar", "/foo" }
function M.get_ancestor_paths()
  local ancestor_paths = {}
  local current_path = vim.fn.getcwd()

  repeat
    table.insert(ancestor_paths, current_path)
    current_path = vim.fn.fnamemodify(current_path, ':h')
  until current_path == '/'

  return ancestor_paths
end

--- Returns whether or not `filename` exists in `path`
---
---@param path string
---       example: "/path/to/my_app"
---@param filename string
---       example: "Gemfile"
---@return boolean
function M.has_file(path, filename)
  return vim.fn.filereadable(path .. "/" .. filename) == 1
end

function M.log(msg)
  local log_path = vim.fn.stdpath("cache") .. "/" .. "rspec-nvim.log"
  vim.fn.writefile({msg}, log_path, "a")
end

return M
