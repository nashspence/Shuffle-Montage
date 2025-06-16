#!/usr/bin/env bats
load "./test_helper.bash"

@test "each clip length is within bounds" {
  run zsh ./shuffle-montage.sh "$VIDEO_DIR"/test*.mp4
  assert_success
  log_file=$(ls "$HOME/Desktop"/Montage-Shuffle-*.log)
  [ -f "$log_file" ]

  outside=$(grep '^Clip ' "$log_file" | awk -F'len=' -v min="$MIN_CLIP" -v max="$MAX_CLIP" '{sub(/s$/, "", $2); if($2+0<min || $2+0>max) print $2}')
  [ -z "$outside" ]
}
