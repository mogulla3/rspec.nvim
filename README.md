# rspec.nvim

RSpec runner for Neovim. Written in Lua.

## Features

- Asynchronous rspec execution. Does not block your editing.
- Various rspec execution commands (inspired by test.vim). See [Commands](#Commands).
- Smart selection of rspec commands and execution path.
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
