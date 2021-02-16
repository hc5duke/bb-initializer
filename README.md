# bb-initializer

video and srt extractor

## Requirements

- handbrakecli
- ffmpeg
- ruby 2.x

## Running

### Input:

- DVD volume

### Output:

- video chapters (no audio)
    - default min length=600sec
- subtitles
    - default=first stream

### Env args:
  - `VOLUME`
    - string
    - Volume name
    - Uses case-ignore grep, i.e. "ABC|DEF" will match /Volume/ABC_1 and /Volume/DEF_2 (but only the first one will run)
  - `SRT`
    - number
    - subtitle stream
  - `MINLEN`
    - number (in seconds)
    - default: 10 minutes
    - minimum length of track to be scanned
  - `SEASON`
    - number
  - `EPISODE`
    - number
    - episode number to call first track
    - on subsequent tracks, episode number will increment by 1

### Example usage:

```bash
$ SEASON=3 EPISODE=10 VOLUME=KOTH make
```
