#!/usr/bin/env bats
load "./test_helper.bash"

@test "script fails with no input" {
  run zsh ./shuffle-montage.sh
  assert_failure
}
