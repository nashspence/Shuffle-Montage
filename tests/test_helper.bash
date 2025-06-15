load '/usr/lib/bats/bats-support/load'
load '/usr/lib/bats/bats-assert/load'

setup() {
  TEST_ROOT=$(mktemp -d)
  export HOME="$TEST_ROOT/home"
  mkdir -p "$HOME/Desktop"
  export PATH="$(pwd)/tests/bin:$PATH"
  export OSASCRIPT_LOG="$TEST_ROOT/osascript.log"
  export TARGET_SEC=120
  export MIN_CLIP=5
  export MAX_CLIP=15
  VIDEO_DIR="$TEST_ROOT/videos"
  mkdir -p "$VIDEO_DIR"
  for i in $(seq 1 24); do
    dur=$(( 60 + (i * 7 % 61) ))
    ffmpeg -y -f lavfi -i "testsrc=duration=${dur}:size=64x64:rate=1" \
      -c:v libx264 -pix_fmt yuv420p -preset ultrafast -crf 28 \
      "$VIDEO_DIR/test${i}.mp4" >/dev/null 2>&1
  done
}

teardown() {
  rm -rf "$TEST_ROOT"
}
