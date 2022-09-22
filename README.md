# rspec.nvim

RSpec runner for Neovim. Written in Lua.

## Features

- Asynchronous rspec execution. Does not block your editing.
- Various rspec execution commands (inspired by test.vim). See [Commands](#Commands).
- Smart selection of rspec command and execution path. See [Commands](#Commands).
- Automatically add failed examples to the quickfix list.
- Quickly view last results with floating window.

## Requirements

- Neovim >= 0.7
- RSpec >= 3.9.0

## Installation

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "mogulla3/rspec.nvim" }
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug "mogulla3/rspec.nvim"
```

## Commands

|Command|Description|
|:--|:--|
|`:RunCurrentSpec`|Run rspec on the current file.|
|`:RunNearestSpec`|Run rspec on the example nearest to the cursor position.|
|`:RunLastSpec`|Re-run rspec with the last command executed.|
|`:RunFailedSpec`|Run rspec on the current file with `--only-failures` option.|
|`:ShowLastSpecResult`|Show last spec result on floating window.|

## Smart selection of rspec command and execution path

### `rspec` command

rspec.nvim selects rspec commands to run in the following order.

1. `bin/rspec`
1. `bundle exec rspec`
1. `rspec`

Search the parent directory from the current directory and determine if `bin/rspec` or `Gemfile` exists.

Assuming the development of Rails applications or the use of Bundler, the order of priority is considered the most natural. Currently, this priority cannot be changed.

### execution path

If `bin/rspec` or `bundle exec rspec` is selected, the current directory is automatically moved and rspec is executed.

- `bin/rspec` : Go to a directory in the same hierarchy as the `bin/`.
- `bundle exec rspec` : Go to the directory where `Gemfile` is located

So you can run rspec from neovim even if your current directory is somewhere deep.
