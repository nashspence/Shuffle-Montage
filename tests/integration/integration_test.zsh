#!/usr/bin/env zsh
set -euo pipefail
set -x

log_file=""
cleanup() {
  ec=$?
  if [[ $ec -ne 0 ]]; then
    echo "::group::integration log"
    if [[ -n "$log_file" && -f "$log_file" ]]; then
      cat "$log_file"
    else
      ls -l "$HOME/Desktop" >&2 || true
      for f in "$HOME"/Desktop/Montage-Shuffle-*.log; do
        [[ -f "$f" ]] && { cat "$f"; break; }
      done
    fi
    echo "::endgroup::"
  fi
}
trap cleanup EXIT

TEST_ROOT=$(mktemp -d)
export HOME="$TEST_ROOT/home"
mkdir -p "$HOME/Desktop"
VIDEO_DIR="$TEST_ROOT/videos"
mkdir -p "$VIDEO_DIR"

for i in {1..4}; do
  ffmpeg -y -f lavfi -i "testsrc=duration=40:size=64x64:rate=1" \
    -c:v libx264 -pix_fmt yuv420p -preset ultrafast -crf 28 \
    "$VIDEO_DIR/test${i}.mp4" >/dev/null 2>&1
done

export TARGET_SEC=30
export MIN_CLIP=5
export MAX_CLIP=10

zsh ./shuffle-montage.sh "$VIDEO_DIR"/*.mp4

log_file=$(ls "$HOME/Desktop"/Montage-Shuffle-*.log)
[ -f "$log_file" ] || { echo "Log file not found" >&2; exit 1; }

montage_file=$(ls "$HOME/Desktop"/montage_*.mkv)
[ -f "$montage_file" ] || { echo "Montage file not found" >&2; exit 1; }

duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$montage_file")
dur=${duration%.*}
diff=$(( dur - TARGET_SEC ))
(( diff < 0 )) && diff=$(( -diff ))
(( diff <= 1 )) || { echo "Unexpected duration $dur" >&2; exit 1; }

echo "Integrated test passed."
