# rspec.nvim

Test Runner for RSpec.

## Features

TODO

## Commands

|Command|Description|
|:--|:--|
|`:RunCurrentSpecFile`|Run rspec on the current file.|
|`:RunNearestSpec`|Run rspec on the test nearest to the current cursor position.|
|`:RunLastSpec`|Re-run rspec with the last command executed.|
|`:RunLastFailedSpec`|Run rspec on the current file with `--only-failures` option.|

## TODOs

- About running rspec
  - [x] Run rspec to file (current buffer).
  - [x] Run rspec to close to the cursor potision.
  - [x] Run rspec to last test run.
  - [ ] Run rspec with the `--only-failures` option.
- About rspec commands at runtime
  - [x] Move the current directory to a nice place and run it.
    - Since `rspec` can only be run from project root.
  - [x] rspec in the following order of priority
    - `bin/rspec` -> `bundle exec rspec` -> `rspec` (global)
- About test execution
  - [x] (try) Run rspec as background job
  - [@] (try) Displaying progress in a floating window during test execution
  - [@] (try) When the test is completed, report the results in a floating window.
  - [ ] (try) No other jobs are accepted while a test job is running.
  - [x] (try) If a failed test exists, register it with quickfix and automatically open it.
- About the results of the test
  - [x] Failed tests are thrown into quickfix.
  - [x] The last test results can be viewed in a floating window. (success or failure)
  - [ ] Color the last test result.
  - [ ] When the cursor is hovered over a failed test, detailed information is displayed in a floating window.
- About error handling
  - [ ] Consider cases that do not match rspec filename format. (expected: `_spec.rb`)
  - [ ] Consider the case where `rspec` is not installed.
- About docs
  - [ ] Write docs.
- About config
  - [ ] Allow users to change above behaviors in settings.
  - [ ] Allow command line options to be passed freely.
  - [ ] Debug output can be enabled in the settings.
- Others
  - [ ] If focused spec is found, display it in the message.
  - [ ] Write tests.
