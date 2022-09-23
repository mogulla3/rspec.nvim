# rspec.nvim

RSpec runner for Neovim. Written in Lua.

When spec passed:

<img src="https://user-images.githubusercontent.com/1377455/191960812-480d2ef8-33a2-498f-b5e9-06a0431547da.gif" alt="rspec_nvim_success_demo" width="80%"/>

When spec failed:

<img src="https://user-images.githubusercontent.com/1377455/191962794-7e8da6c5-06cf-4c4c-a4f0-98eecb056756.gif" alt="rspec_nvim_fail_demo" width="80%"/>

## Features

- Asynchronous rspec execution. Does not block your editing
- Various rspec execution commands (inspired by test.vim)
- Smart selection of rspec command and execution path
- Automatically add failed examples to the quickfix list
- Quickly view last results with floating window

## Requirements

- Neovim >= 0.7
- RSpec >= 3.9.0

## Installation

[packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "mogulla3/rspec.nvim" }
```

[vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug "mogulla3/rspec.nvim"
```

## Usage

### Setup

When using the default settings:

```lua
require('rspec').setup()
```

Or if you want to change some settings:

```lua
require('rspec').setup(
  -- File format to allow rspec to run
  allowed_file_format = function(filename)
    return vim.endswith(filename, "_spec.rb")
  end,

  -- Whether or not to focus on a window when `ShowLastSpecResult` command executed.
  focus_on_last_spec_result_window = true,

  -- Whether or not to open the quickfix window when the spec fails.
  open_quickfix_when_spec_failed = true,

  -- File path to save the last spec result.
  last_result_path = vim.fn.stdpath("data") .. "/" .. "rspec_last_result",

  -- File path to save the last failed spec result.
  last_failed_result_path = vim.fn.stdpath("data") .. "/" .. "rspec_last_failed_result",
)
```

### Commands

Then, you can run rspec and view the results through the following command.

|Command|Description|
|:--|:--|
|`:RSpecCurrentFile`|Run rspec on the current file.|
|`:RSpecNearest`|Run rspec on the example nearest to the cursor position.|
|`:RSpecRerun`|Rerun rspec with the last command.|
|`:RSpecOnlyFailures`|Run rspec on the current file with `--only-failures` option.|
|`:RSpecShowLastResult`|Show last spec result on floating window.|

Below is the recommended key mappings.

```lua
vim.keymap.set("n", "<leader>rn", ":RSpecNearest<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>rf", ":RSpecCurrentFile<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>rr", ":RSpecRerun<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>rF", ":RSpecOnlyFailures<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>rs", ":RSpecShowLastResult<CR>", { noremap = true, silent = true })
```

## Smart selection of rspec command and execution path

### `rspec` command

rspec.nvim selects rspec commands to run in the following order.

1. `bin/rspec`
1. `bundle exec rspec`
1. `rspec`

Search the parent directory from the current directory and determine if `bin/rspec` or `Gemfile` exists.

Assuming the development of Rails applications or the use of [Bundler](https://bundler.io/), the order of priority is considered the most natural.

### execution path

If `bin/rspec` or `bundle exec rspec` is selected, the current directory is automatically moved and then rspec is run.

- `bin/rspec` : Go to a directory in the same hierarchy as the `bin/`.
- `bundle exec rspec` : Go to the directory where `Gemfile` is located

So you can run rspec from neovim even if your current directory is somewhere deep.

## Asynchronous rspec execution

rspec.nvim runs `rspec` asynchronously, so it doesn't block your editing.

<img src="https://user-images.githubusercontent.com/1377455/191964429-4a2edc90-4c42-4d88-b444-c66f1ac47130.gif" alt="rspec_nvim_async_run" width="60%"/>

## quickfix integration

If there are any failed tests, they are added to the quickfix list. So you can jump to failed tests quickly!
