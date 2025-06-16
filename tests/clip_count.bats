#!/usr/bin/env bats
load "./test_helper.bash"

@test "plans clip count to match target" {
  run zsh ./shuffle-montage.sh "$VIDEO_DIR"/test*.mp4
  assert_success
  log_file=$(ls "$HOME/Desktop"/Montage-Shuffle-*.log)
  [ -f "$log_file" ]

  planned=$(grep -E "^Planning" "$log_file" | awk '{print $2}')
  expected=$(( (2*TARGET_SEC) / (MIN_CLIP + MAX_CLIP) ))
  (( planned == expected ))

  total_clips=$(grep -c '^Clip ' "$log_file")
  (( total_clips == planned ))

  total_len=$(awk -F"len=" '/Clip/{split($2,a,"s");sum+=a[1]}END{print sum}' "$log_file")
  (( total_len == TARGET_SEC ))

  montage_file=$(ls "$HOME/Desktop"/montage_*.mkv)
  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$montage_file")
  dur=${duration%.*}
  (( dur == TARGET_SEC ))
}
