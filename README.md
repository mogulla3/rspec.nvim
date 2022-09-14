# rspec.nvim

Test Runner for RSpec.

## Features

TODO

## Commands

|Command|Description|
|:--|:--|
|`:RunCurrentSpec`|Run rspec on the current file.|
|`:RunNearestSpec`|Run rspec on the spec nearest to the current cursor position.|
|`:RunFailedSpec`|Run rspec on the current file with `--only-failures` option.|
|`:RunLastSpec`|Re-run rspec with the last command executed.|
|`:ShowLastSpecResult`|Show last spec result on floating window.|

## TODOs

- About running rspec
  - [x] Run rspec to file (current buffer).
  - [x] Run rspec to close to the cursor potision.
  - [x] Run rspec to last test run.
  - [x] Run rspec with the `--only-failures` option.
- About rspec commands at runtime
  - [x] Move the current directory to a nice place and run it.
    - Since `rspec` can only be run from project root.
  - [x] rspec in the following order of priority
    - `bin/rspec` -> `bundle exec rspec` -> `rspec` (global)
- About test execution
  - [x] Run rspec as background job.
  - [x] Displaying progress in a floating window during test execution.
  - [x] If a failed test exists, register it with quickfix and automatically open it.
  - [x] ~When the test is completed, report the results in a floating window.~
  - [ ] No other jobs are accepted while a test job is running.
- About the results of the test
  - [x] Failed tests are thrown into quickfix.
  - [x] The last test results can be viewed in a floating window. (success or failure)
  - [x] Avoid duplicate floating windows for viewing last test results.
  - [x] Setup keymap on float window. (for easy to close)
  - [@] Show a single sentence summarizing the results of the test run on.
  - [ ] Color the last test result.
  - [ ] When the cursor is hovered over a failed test, detailed information is displayed in a floating window.
  - [ ] Show the sign of the test result on the editor
- About error handling
  - [x] Consider cases that do not match rspec filename format. (expected: `_spec.rb`)
  - [ ] Consider the case where `rspec` is not installed.
- About docs
  - [ ] Write docs.
- About config
  - [x] Allow users to change above behaviors in settings.
  - [ ] Debug output can be enabled in the settings.
- Others
  - [ ] Write tests.
  - [ ] checkhealth
  - [x] stylua
  - [ ] CI with GitHub Actions
