# Shuffle-Montage

Shuffle-Montage is a small shell script that builds quick video montages from a set of input files. It is useful for turning large amounts of continuous life‑logging footage—such as a full day of wearable camera video—into a short, watchable highlight reel.

The script uses a **stochastic within-partition** approach: it divides the overall timeline into equal partitions and then picks a random clip from each partition. This method is fast and avoids any deeper analysis of the videos.

## Requirements

- macOS with `zsh`, `ffmpeg`, `ffprobe`, `awk`, and `realpath`
- `osascript` for desktop notifications

## Usage

Run the script with the video files you want to sample from:

```zsh
./shuffle-montage.sh /path/to/video1.mp4 /path/to/video2.mp4 [...]
```

The resulting montage is written to your Desktop as `montage_<timestamp>.mkv`. A log file named `Montage-Shuffle-<timestamp>.log` is also placed on the Desktop.

## License

This project is licensed under the [MIT License](LICENSE).
