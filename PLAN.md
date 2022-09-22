## rspec commands

- [x] Run rspec to file (current buffer)
- [x] Run rspec to close to the cursor potision
- [x] Run rspec to last test run
- [x] Run rspec with the `--only-failures` option

## Selecting RSpec command to run

- [x] Select in the following order of priority
  - `bin/rspec` -> `bundle exec rspec` -> `rspec` (global)
- [x] Automatically move paths when running rspec
  - Since `rspec` can only be run from project root

## Details on running RSpec

- [x] Run rspec as background job to avoid blocking user editing.
- [x] Displaying progress in a floating window during rspec execution.
- [x] Prevent multiple runs of RSpec

## About the results of the test

- [x] If failed tests exist, add them with quickfix and automatically open quickfix window
- [x] Display a one-line summary of test results
- [x] The last test results can be viewed in a floating window
- [x] Setup keymaps on float window. (for easy to close)
- [x] Color the last test result.
- [x] Avoid duplicate floating windows for viewing last test results.
- [x] Set the cursor position on the floating window to the beginning.
- [ ] When the cursor is hovered over a failed test, detailed information is displayed in a floating window.
- [ ] Show the sign of the test result on the editor

## Error handling

- [x] Consider cases that do not match rspec filename format. (expected: `_spec.rb`)
- [x] Consider the case where `rspec` is not installed.

## Configuration

- [x] Allow users to change above behaviors in settings.

## Others

- [x] stylua
- [ ] Make REAMDE.md more attractive *
- [ ] Write docs
- [ ] Write tests
- [ ] Support checkhealth
- [ ] Setup CI with GitHub Actions

## Ideas

- [] Go to the spec file corresponding to the open buffer (and vice versa)
- [] If the spec file corresponding to the open buffer does not exist, create a spec file.
