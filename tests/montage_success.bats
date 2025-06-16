#!/usr/bin/env bats
load "./test_helper.bash"

@test "creates montage and log files" {
  run zsh ./shuffle-montage.sh "$VIDEO_DIR"/test*.mp4
  assert_success
  montage_file=$(ls "$HOME/Desktop"/montage_*.mkv)
  [ -f "$montage_file" ]
  log_file=$(ls "$HOME/Desktop"/Montage-Shuffle-*.log)
  [ -f "$log_file" ]
  cat "$log_file"
}
