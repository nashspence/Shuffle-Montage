#!/usr/bin/env bats
load "./test_helper.bash"

@test "montage duration equals TARGET_SEC" {
  run zsh ./shuffle-montage.sh "$VIDEO_DIR"/test*.mp4
  assert_success
  montage_file=$(ls "$HOME/Desktop"/montage_*.mkv)
  [ -f "$montage_file" ]
  log_file=$(ls "$HOME/Desktop"/Montage-Shuffle-*.log)
  [ -f "$log_file" ]

  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$montage_file")
  dur=${duration%.*}
  (( dur == TARGET_SEC ))

  total_len=$(awk -F"len=" '/Clip/{split($2,a,"s");sum+=a[1]}END{print sum}' "$log_file")
  (( total_len == dur ))
}
