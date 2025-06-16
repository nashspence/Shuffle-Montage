#!/usr/bin/env zsh
set -euo pipefail

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
(( dur == TARGET_SEC )) || { echo "Unexpected duration $dur" >&2; exit 1; }

echo "Integrated test passed."
