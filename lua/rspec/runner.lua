local config = require("rspec.config")
local logger = require("rspec.logger")

local Runner = {}

--- Open a window showing rspec progress
---
---@return { win_id: number, bufnr: number }
local function create_progress_window()
  local message = "Running RSpec..."
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Render floating window on right bottom
  local opts = {
    relative = "win",
    anchor = "SE",
    focusable = false,
    row = vim.fn.winheight(0) - 2,
    col = vim.fn.winwidth(0) - 4,
    width = string.len(message),
    height = 1,
    style = "minimal",
    border = "rounded",
  }

  local win_id = vim.api.nvim_open_win(bufnr, false, opts)
  vim.api.nvim_win_set_buf(win_id, bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { message })
  vim.api.nvim_win_set_option(win_id, "winhl", "Normal:ErrorFloat")

  return { win_id = win_id, bufnr = bufnr }
end

---@param progress_window { win_id: number, bufnr: number }
local function cleanup_progress_window(progress_window)
  vim.api.nvim_win_close(progress_window.win_id, true)
  vim.api.nvim_buf_delete(progress_window.bufnr, { force = true })
end

--- Build a summary of RSpec execution results.
--- The return value (`chunk`) is assumed to be passed to the `nvim_echo` function.
---
---@param exit_code number
---@return string[] # format: { message, hl_group }
local function build_summary_chunk(exit_code)
  local last_result = {}
  if vim.fn.getfsize(config.last_result_path) > 0 then
    local last_result_json = vim.fn.readfile(config.last_result_path)[1]
    last_result = vim.json.decode(last_result_json)
  end

  local messages = {
    [0] = {
      label = "PASSED",
      hl_group = "RSpecPassed",
      text = last_result.summary_line,
    },
    [1] = {
      label = "FAILED",
      hl_group = "RSpecFailed",
      text = last_result.summary_line,
    },
    default = {
      label = "ERROR",
      hl_group = "RSpecAborted",
      text = "exit_code=" .. exit_code,
    },
  }

  local message = messages[exit_code] or messages["default"]

  return { string.format("[rspec.nvim] %s : %s", message.label, message.text), message.hl_group }
end

--- Notify a summary of RSpec execution results
---
---@param exit_code number
local function notify_rspec_summary(exit_code)
  local summary_chunks = build_summary_chunk(exit_code)
  vim.api.nvim_echo({ summary_chunks }, true, {})
end

--- Add failed examples to quickfix lists.
--- And if `open_quickfix_when_spec_failed` is enabled, open the quickfix window immediately
local function add_failed_examples_to_quickfix()
  -- In the case of errors prior to running RSpec, such as SyntaxError, nothing is written to the file.
  -- Therefore, the file size is used for verification.
  if vim.fn.getfsize(config.last_failed_result_path) < 1 then
    return
  end

  local failed_examples = vim.fn.readfile(config.last_failed_result_path)
  local lines = vim.list_extend({ "[rspec.nvim] Failed examples" }, failed_examples)
  vim.fn.setqflist({}, "r", { efm = "%f:%l:%m", lines = lines })

  if config.open_quickfix_when_spec_failed then
    vim.api.nvim_command("copen")
  end
end

--- Run rspec command
---
---@param command string[]
---@param exec_path string
---@return number # job id (return value of `jobstart`)
function Runner.run_rspec(command, exec_path)
  vim.api.nvim_command("cclose")

  local progress_window = create_progress_window()

  logger.log(vim.inspect(command))
  logger.log(vim.inspect(exec_path))

  local job_id = vim.fn.jobstart(command, {
    cwd = exec_path,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      vim.g.last_command_stdout = data
    end,
    on_stderr = function(_, data, _)
      vim.g.last_command_stderr = data
    end,
    ---@see `:help on_exit`
    on_exit = function(_, exit_code, _)
      cleanup_progress_window(progress_window)

      notify_rspec_summary(exit_code)

      if exit_code == 1 then
        add_failed_examples_to_quickfix()
      end
    end,
  })

  return job_id
end

return Runner
