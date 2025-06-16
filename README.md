# Shuffle-Montage

Shuffle-Montage is a small shell script that builds quick video montages from a set of input files. It is useful for turning large amounts of continuous life‑logging footage—such as a full day of wearable camera video—into a short, watchable highlight reel.

The script uses a **stochastic within-partition** approach. The overall timeline
of all input videos is divided into equal partitions and then a random clip is
chosen from inside each partition. This method is fast and avoids any deeper
analysis of the videos.

## Requirements

- macOS with `zsh`, `ffmpeg`, `ffprobe`, `awk`, and `realpath`
- `osascript` for desktop notifications

## Usage

Run the script with the video files you want to sample from:

```zsh
./shuffle-montage.sh /path/to/video1.mp4 /path/to/video2.mp4 [...]
```

The resulting montage is written to your Desktop as `montage_<timestamp>.mkv`. A log file named `Montage-Shuffle-<timestamp>.log` is also placed on the Desktop.

### Environment Variables

Several optional environment variables control clip planning:

- `TARGET_SEC` — desired total duration in seconds (default `120`)
- `MIN_CLIP` / `MAX_CLIP` — bounds for individual clip length

## Features

- [**fails without input**](tests/no_input.bats#L4-L7) — exits with an error and
  shows a notification if no video files are given.
- [**sends desktop notifications**](tests/notifications.bats#L4-L12) — notifies when
  the shuffle montage starts and when the finished video is placed on the
  Desktop.
- [**creates montage and log files**](tests/montage_success.bats#L4-L12) — writes
  `montage_<timestamp>.mkv` and `Montage-Shuffle-<timestamp>.log` to the
  Desktop.
- [**plans clip count to match target**](tests/clip_count.bats#L4-L24) — computes how many
  clips to use from `TARGET_SEC`, `MIN_CLIP`, and `MAX_CLIP` so the total
  montage length equals `TARGET_SEC`.
- [**clip length within bounds**](tests/clip_length_range.bats#L4-L12) — every clip's
  duration stays between `MIN_CLIP` and `MAX_CLIP`.

## How it Works

1. **Measure durations** – Each input file's length is read with `ffprobe` and
   the files are treated as one long timeline.
2. **Determine clip count** – The number of clips `N` is computed as
   `N = (2 * TARGET_SEC) / (MIN_CLIP + MAX_CLIP)`. This gives roughly the clip
   count needed if every clip were the average of the minimum and maximum
   durations.
3. **Plan clip lengths** – For each of the `N` partitions a random length between
   `MIN_CLIP` and `MAX_CLIP` is chosen while ensuring that the total of all
   lengths equals `TARGET_SEC`.
4. **Pick clip positions** – The combined timeline is divided into `N` equal
   partitions. Within each partition the script picks a random start time so that
   the chosen clip fits entirely inside that partition.
5. **Extract and combine** – Each selected region is extracted with `ffmpeg` and
   written to a temporary file. When all clips are ready they are concatenated
   using `ffmpeg`'s concat demuxer to produce the final montage.

## License

This project is licensed under the [MIT License](LICENSE).
