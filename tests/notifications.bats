#!/usr/bin/env bats
load "./test_helper.bash"

@test "desktop notifications are sent" {
  run zsh ./shuffle-montage.sh "$VIDEO_DIR"/test*.mp4
  assert_success
  [ -f "$OSASCRIPT_LOG" ]
  start_count=$(grep -c "Starting shuffle montage" "$OSASCRIPT_LOG")
  ready_count=$(grep -c "Shuffle montage ready" "$OSASCRIPT_LOG")
  (( start_count == 1 ))
  (( ready_count == 1 ))
}
