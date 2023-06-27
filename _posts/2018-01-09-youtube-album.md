---
layout: post
title: Converting an audio album to a YouTube video
date: 2018-01-09
---
{% include changelog.html changes="Aug 23, 2021 | Adding youtube-chapters script" %}

YouTube is a great way to quickly disseminate obscure, long-tail music albums that carry cultural significance. As long as you remain under the radar of our friends at the music labels, of course :wink:

Here's a recipe to prepare audio files for YouTube upload. The video is a looping slideshow of the images contained in the album's artwork. Here's a couple of examples of this recipe's output:

{% oembed https://www.youtube.com/watch?v=qjlDT819Q3s %}

{% oembed https://www.youtube.com/watch?v=Lii7NCULPBA %}

Requires: `imagemagick ffmpeg metaflac sox`

If you have just one cover image to show, and you want one video file per track, you can take the following shortcut:

```bash
for f in *.flac; do ffmpeg -loop 1 -i cover.png -i "$f" -shortest -codec:v libx264 -crf 21 -bf 2 -flags +cgop -pix_fmt yuv420p -codec:a aac -strict -2 -b:a 384k -r:a 48000 -movflags faststart "${f/.flac/.mp4}"; done
```

Otherwise, read on:

 Convert images to required size. Here I assume PNG files and output to `png/` folder. See [http://www.imagemagick.org/Usage/crop/#extent](http://www.imagemagick.org/Usage/crop/#extent)

```bash
for f in *.png; do convert "$f" -resize 800x600 -gravity center -background black -extent 800x600 png/"$f".png; done
```

 Generate video out of pngs. Here each image is shown for 20 seconds. See [https://trac.ffmpeg.org/wiki/Slideshow](https://trac.ffmpeg.org/wiki/Slideshow) and [https://en.wikibooks.org/wiki/FFMPEG_An_Intermediate_Guide/image_sequence#Filename_patterns](https://en.wikibooks.org/wiki/FFMPEG_An_Intermediate_Guide/image_sequence#Filename_patterns)

```bash
ffmpeg -framerate 1/20 -pattern_type glob -i "png/*.png" -c:v libx264 -vf "fps=25,format=yuv420p" png.mp4
```

 Concatenate audio files. See [https://trac.ffmpeg.org/wiki/Concatenate](https://trac.ffmpeg.org/wiki/Concatenate)

```bash
printf "file '%s'\n" ./*.flac > files.txt
ffmpeg -f concat -safe 0 -i files.txt files.flac
```

 Concatenate png video enough times to cover audio duration - in the example below we make 10 copies. See [http://superuser.com/a/1116107/55867](http://superuser.com/a/1116107/55867)

```bash
for i in {.10}; do printf "file '%s'\n" png.mp4 >> pngs.txt; done
ffmpeg -f concat -safe 0 -i pngs.txt -c copy pngs.mp4
```

 Create YouTube video using acceptable encoding settings. See [https://www.virag.si/2015/06/encoding-videos-for-youtube-with-ffmpeg](https://www.virag.si/2015/06/encoding-videos-for-youtube-with-ffmpeg)

```bash
ffmpeg -i pngs.mp4 -i files.flac -shortest -codec:v libx264 -crf 21 -bf 2 -flags +cgop -pix_fmt yuv420p -codec:a aac -strict -2 -b:a 384k -r:a 48000 -movflags faststart youtube.mp4
```

 Generate a YouTube track listing to copy-paste in the video description:

```bash
youtube-playlist.sh *.flac
```

```bash
#!/bin/bash

# youtube-playlist.sh
# Show album track list in YouTube-friendly format including
# clickable track offsets.
#
# Only works with .flac atm :-(
#
# Requires: metaflac sox

start=0
for f in "$@"
do
        offset=$(date -u -d "0 $start sec" +"%H:%M:%S")
        title=$(metaflac "$f" --show-tag=TITLE | sed s/.*=//g)
        trackno=$(metaflac "$f" --show-tag=TRACKNUMBER | sed s/.*=//g)
        echo "$offset" "$trackno" "$title"
        end=$(soxi -D "$f")
        start=$(bc -l <<< "$start + $end")
done
```

 Generate a video file with chapters:

```bash
youtube-chapters.sh *.flac > chapters
ffmpeg -i youtube.mp4 -i chapters -map_metadata 1 -codec copy youtube-chapters.mp4
```

```bash
#!/bin/bash

# youtube-chapters.sh
# Show album track list in ffmpeg metadata format
#
# Only works with .flac atm :-(
#
# Requires: metaflac sox

# https://stackoverflow.com/a/43444305/209184
round() {
	printf "%.${2}f" "${1}"
}

echo ";FFMETADATA1"

offset=0
for f in "$@"
do
	start=$(round $offset 0)
	echo "[CHAPTER]"
	echo "TIMEBASE=1/1000"
	echo "START=$start"
	delta=$(soxi -D "$f")
	offset=$(bc -l <<< "$offset + ($delta * 1000)")
	end=$(round $offset 0)
	echo "END=$end"
	title=$(metaflac "$f" --show-tag=TITLE | sed s/.*=//g)
	echo "TITLE=$title"
done
```

Originally published as a [GitHub gist](https://gist.github.com/infojunkie/6f9e6d0c9dce9be44116b7a828accc20).
