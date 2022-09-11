local log_path = vim.fn.stdpath("cache") .. "/" .. "rspec-nvim.log"

Logger = {}

function Logger.log(message)
  vim.fn.writefile({ message }, log_path, "a")
end

return Logger
