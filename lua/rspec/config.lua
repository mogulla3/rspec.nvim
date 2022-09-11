local config = {}

local default_config = {
  -- File name patterns that can run rspec
  -- MEMO: Might as well accept regular expressions.
  allowed_file_format = function(filename)
    return vim.endswith(filename, '_spec.rb')
  end,

  -- Whether or not to focus on a window when `ShowLastSpecResult` command executed.
  focus_on_last_spec_result_window = false,

  -- Whether or not to open the quickfix window when the spec fails.
  open_quickfix_when_spec_failed = true,

  -- "DEBUG(1)", "INFO(2)", "WARN(3)", "ERROR(4)"
  log_level = 'DEBUG',
}

local M = {}

function M.setup(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config)
end

setmetatable(M, {
  __index = function(_, key)
    return config[key]
  end,
})

return M
