local config = {}

local default_config = {
  -- File name patterns that can run rspec
  -- MEMO: Might as well accept regular expressions.
  allowed_file_format = function(filename)
    return vim.endswith(filename, "_spec.rb")
  end,

  -- RSpec formatter. "progress", "p", "documentation" and "d" can be specified.
  -- If none of the above, use "progress".
  formatter = "progress",

  -- Whether or not to focus on a window when `ShowLastSpecResult` command executed.
  focus_on_last_spec_result_window = true,

  -- Whether or not to open the quickfix window when the spec fails.
  open_quickfix_when_spec_failed = true,

  -- File path to save the last spec result.
  last_result_path = vim.fn.stdpath("data") .. "/" .. "rspec_last_result",

  -- File path to save the last failed spec result.
  last_failed_result_path = vim.fn.stdpath("data") .. "/" .. "rspec_last_failed_result",

  -- Command to open the file to jump to.
  -- Examples of other alternatives: vsplit, split, tabedit
  jump_command = "edit",

  -- Directories to ignore when jumping with the RSpecJump command
  --
  -- For example, suppose you want to jump from "src/foo/bar.rb" to "spec/foo/bar_spec.rb".
  --
  -- However, rspec.nvim would by default try to find "spec/src/foo/bar_spec.rb" and return an error saying it cannot be found.
  -- In this case, you would want to treat the "src/" directory as equivalent to the "app/" in Rails or the "lib/" directory in a gem.
  --
  -- So you can specify the following for the ignored_dirs_on_jump option, which will give you the expected jumps.
  -- ```
  -- ignored_dirs_on_jump = { "src" }
  -- ```
  ignored_dirs_on_jump = {},
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
