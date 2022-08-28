# rspec.nvim

Test Runner for RSpec.

## Features

TODO

## TODOs

- About running rspec
  - [] Run rspec to file (current buffer).
  - [] Run rspec to close to the cursor potision.
  - [] Run rspec to last test run.
  - [] Run rspec with the `--only-failures` option.
- About rspec commands at runtime
  - [] Move the current directory to a nice place and run it.
    - Since `rspec` can only be run from project root.
  - [] rspec in the following order of priority
    - `bin/rspec` -> `bundle exec rspec` -> `rspec` (global)
- About the results of the test
  - [] Failed tests are thrown into quickfix.
  - [] The last test results can be viewed in a float window. (success or failure)
- About error handling
  - [] Consider cases that do not match rspec filename format. (expected: `_spec.rb`)
  - [] Consider the case where `rspec` is not installed.
- About docs
  - [] write docs
- Other
  - [] Working with dispatch.vim
  - [] If focused spec is found, display it in the message.
  - [] Allow users to change above behaviors in settings.
  - [] Debug output can be enabled in the settings.
  - [] Other rspec-specific features that may be useful may be implemented.
  - 現在のバッファの番号が返ってくるようだ