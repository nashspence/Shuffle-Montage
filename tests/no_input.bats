#!/usr/bin/env bats
load "./test_helper.bash"

@test "fails without input" {
  run zsh ./shuffle-montage.sh
  assert_failure
}
