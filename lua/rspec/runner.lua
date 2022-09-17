local config = require("rspec.config")
local logger = require("rspec.logger")

local Runner = {}

--- Open a window showing rspec progress
---
---@return number: window id
local function open_progress_window()
  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_width = vim.fn.winwidth(0)
  local win_height = vim.fn.winheight(0)

  -- Render floating window on right bottom
  local opts = {
    relative = "win",
    anchor = "SE",
    focusable = false,
    row = win_height - 2,
    col = win_width - 4,
    width = 16, -- fit to message length
    height = 1,
    style = "minimal",
    border = "rounded",
  }

  local win_id = vim.api.nvim_open_win(bufnr, false, opts)
  vim.api.nvim_win_set_buf(win_id, bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { "Running RSpec..." })
  vim.api.nvim_win_set_option(win_id, "winhl", "Normal:ErrorFloat")

  return win_id
end

--- Run rspec command
---
---@param command table
---@param runtime_path string
---@return number
function Runner.run_rspec(command, runtime_path)
  vim.api.nvim_command("cclose")

  local progress_win_id = open_progress_window()

  logger.log(vim.inspect(command))
  logger.log(vim.inspect(runtime_path))

  -- job_id
  --  0 -> invalid argument
  -- -1 -> cmd is not executable
  local job_id = vim.fn.jobstart(command, {
    cwd = runtime_path,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      vim.g.last_command_stdout = data
    end,
    on_stderr = function(_, data, _)
      vim.g.last_command_stderr = data
    end,
    -- see: help :on_exit
    on_exit = function(_, exit_code, _)
      vim.api.nvim_win_close(progress_win_id, true)

      if exit_code ~= 0 and exit_code ~= 1 then
        vim.api.nvim_echo({ { string.format("[rspec.nvim] command failed (exit_code=%i)", exit_code), "RSpecFailed" } }, true, {})
        return
      end

      local result = nil
      if vim.fn.getfsize(config.last_result_path) > 0 then
        local result_json = vim.fn.readfile(config.last_result_path)[1]
        result = vim.json.decode(result_json)
      end

      if exit_code == 0 then
        vim.api.nvim_echo({ { "[rspec.nvim] spec passed : " .. result.summary_line, "RSpecPassed" } }, true, {})
      else
        -- TODO: Make the message more detailed but in an amount that fits on 1 line.
        vim.api.nvim_echo({ { "[rspec.nvim] spec failed : " .. result.summary_line, "RSpecFailed" } }, true, {})

        -- In the case of errors prior to running RSpec, such as SyntaxError, nothing is written to the file.
        -- Therefore, the file size is used for verification.
        if vim.fn.getfsize(config.last_failed_result_path) > 0 then
          local failed_examples = vim.fn.readfile(config.last_failed_result_path)
          failed_examples = vim.list_extend({ "[rspec.nvim] Failed examples" }, failed_examples)
          vim.fn.setqflist({}, "r", { efm = "%f:%l:%m", lines = failed_examples })

          if config.open_quickfix_when_spec_failed then
            vim.api.nvim_command("copen")
          end
        end
      end
    end,
  })

  if job_id < 1 then
    vim.notify(string.format("[rspec.nvim] command failed (%i)", job_id), vim.log.levels.ERROR)
  end

  return job_id
end

return Runner
