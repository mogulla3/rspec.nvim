local config = {}

local default_config = {
  -- File name patterns that can run rspec
  -- MEMO: Might as well accept regular expressions.
  allowed_file_format = function(filename)
    return vim.endswith(filename, "_spec.rb")
  end,

  -- Whether or not to focus on a window when `ShowLastSpecResult` command executed.
  focus_on_last_spec_result_window = true,

  -- Whether or not to open the quickfix window when the spec fails.
  open_quickfix_when_spec_failed = true,

  -- File path to save the last failed spec result.
  last_failed_spec_path = vim.fn.stdpath("data") .. "/" .. "rspec_last_failed_spec",
}

local Config = {}

function Config.setup(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config)
end

setmetatable(Config, {
  __index = function(_, key)
    return config[key]
  end,
})

return Config