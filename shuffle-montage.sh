#!/usr/bin/env zsh
set -euo pipefail

LOGFILE="$HOME/Desktop/Montage-Shuffle-$(date +'%Y%m%dT%H%M%S').log"
touch "$LOGFILE" 2>/dev/null || { echo "Cannot write to '$LOGFILE'." >&2; exit 1; }
exec 2>>"$LOGFILE"
command -v osascript >/dev/null 2>&1 && \
  osascript -e "tell application \"Terminal\" to do script \"tail -f '$LOGFILE'\"" || true

START_TIME="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "Started at $START_TIME" >&2
trap 'EC=$?; ET=$(date -u "+%Y-%m-%d %H:%M:%S UTC"); echo "Exited with code $EC at $ET" >&2' EXIT

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

notify() {
  command -v osascript >/dev/null 2>&1 && \
    osascript -e "display notification \"$*\" with title \"Montage Shuffle\"" || true
}

FILES=( "$@" )
if (( ${#FILES[@]} == 0 )); then
  notify "No files selected; aborting"
  echo "No input files. Exiting." >&2
  exit 1
fi
echo "${#FILES[@]} file(s) selected" >&2
notify "Starting shuffle montage for ${#FILES[@]} file(s)…"

for cmd in ffmpeg ffprobe awk realpath; do
  command -v $cmd >/dev/null || { echo "'$cmd' not found"; exit 1; }
done

: "${TARGET_SEC:=120}"
: "${MIN_CLIP:=4}"
: "${MAX_CLIP:=12}"

typeset -a durations prefix
file_count=${#FILES[@]}
prefix[1]=0

for (( i=1; i<=file_count; i++ )); do
  file="${FILES[i]}"
  d=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
  dur=${d%.*}
  durations[i]=$dur
  if (( i > 1 )); then
    prefix[i]=$(( prefix[i-1] + durations[i-1] ))
  fi
done

total_sec=$(( prefix[file_count] + durations[file_count] ))
echo "Combined timeline: ${total_sec}s" >&2

N=$(( (2*TARGET_SEC) / (MIN_CLIP + MAX_CLIP) ))
(( N < 1 )) && { echo "Invalid clip count"; exit 1; }
echo "Planning $N clips" >&2

typeset -a LENS
sum=0
for (( i=1; i<=N; i++ )); do
  if (( i == N )); then
    LENS[i]=$(( TARGET_SEC - sum ))
  else
    rem=$(( TARGET_SEC - sum ))
    left=$(( N - i ))
    lo=$MIN_CLIP; hi=$MAX_CLIP
    min_ok=$(( rem - left*MAX_CLIP )); (( min_ok > lo )) && lo=$min_ok
    max_ok=$(( rem - left*MIN_CLIP )); (( max_ok < hi )) && hi=$max_ok
    (( lo > hi )) && { echo "Cannot fit clip lengths"; exit 1; }
    LENS[i]=$(( RANDOM % (hi - lo + 1) + lo ))
    sum=$(( sum + LENS[i] ))
  fi
done

TMPDIR=$(mktemp -d)
CLIP_LIST="$TMPDIR/clip_list.txt"
: > "$CLIP_LIST"

PART_DUR=$(awk 'BEGIN{printf "%f", '"$total_sec"'/'"$N"'}')
echo "Each partition ≈ ${PART_DUR}s" >&2

for (( i=1; i<=N; i++ )); do
  L=${LENS[i]}
  part_start=$(awk 'BEGIN{printf "%f", ('"$((i-1))"' * '"$PART_DUR"')}')
  max_off=$(awk 'BEGIN{printf "%f", '"$PART_DUR"'-'"$L"'}')
  off=$(awk 'BEGIN{srand(); printf "%f", rand()*'"$max_off"'}')
  global_start=$(awk 'BEGIN{printf "%f", '"$part_start"' + '"$off"'}')

  for (( j=1; j<=file_count; j++ )); do
    if (( global_start >= prefix[j] && global_start < prefix[j] + durations[j] )); then
      file_index=$j
      break
    fi
  done
  file="${FILES[file_index]}"
  local_start=$(awk 'BEGIN{printf "%f", '"$global_start"' - '"${prefix[file_index]}"'}')

  out_clip="$TMPDIR/clip${i}.mkv"
  echo "Clip $i: file='${file##*/}', start=${local_start}s, len=${L}s" >&2

  ffmpeg -hide_banner -loglevel error -y -ss "$local_start" -i "$file" -t "$L" -c copy -avoid_negative_ts make_zero "$out_clip"

  printf "file '%s'\n" "$out_clip" >>"$CLIP_LIST"
done

OUT_DESKTOP="$HOME/Desktop/montage_$(date +'%Y%m%d_%H%M%S').mkv"
echo "Concatenating → $OUT_DESKTOP" >&2

ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "$CLIP_LIST" -c copy -movflags +faststart "$OUT_DESKTOP"
ffmpeg -hide_banner -loglevel error -y -i "$OUT_DESKTOP" -t "$TARGET_SEC" -c copy -movflags +faststart "$OUT_DESKTOP.tmp"
mv "$OUT_DESKTOP.tmp" "$OUT_DESKTOP"

rm -rf "$TMPDIR"
echo "Done → $OUT_DESKTOP" >&2
notify "Shuffle montage ready on your Desktop!"
