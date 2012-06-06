#/usr/bin/bash
ffmpeg -i $1 -vcodec copy -acodec copy output.mp4
MP4Box -raw 1 output.mp4
MP4Box -raw 2 output.mp4
rm output.mp4
MP4Box -add output_track1.h264 -add output_track2.aac $2
rm output_track1.h264
rm output_track2.aac
