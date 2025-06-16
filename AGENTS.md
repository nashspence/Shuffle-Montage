# Agent Instructions

- Do **not** run the test suite locally. The GitHub Actions workflows handle all testing.
- Any new or updated tests should be added to the repository and will run automatically when a pull request is opened.
- Avoid invoking `bats`, `zsh tests/integration/integration_test.zsh`, or similar commands in the container.
