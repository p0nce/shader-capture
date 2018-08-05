#!/bin/sh
./shader-capture -fs shader1.glsl -fps 30 -t 10 -x 16 | ffmpeg -i - -vb 10000k shader1.mp4