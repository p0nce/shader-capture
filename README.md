This repositery contains several programs to process or generate Y4M files.

- `shader-capture`: capture a shader into a video
- `y4m-merge`: merge neighbouring frames (large speed-up)
- `y4m-play`: open a SDL window and plays the Y4M
- `y4m2yuv`: Y4M to YUV conversion

### What is `shader-capture`?

`shader-capture` is a tool to turn a GLSL fragment shader into a raw video.
It is designed to work out-of-the-box with shaders made with [http://glslsandbox.com/](http://glslsandbox.com/)
The output video is Y4M using the Rec. 709 color space with no chroma-subsampling (4:4:4).

### What is `y4m-merge`?

`y4m-merge` merges adjacent frames of an input Y4M video. This is mostly useful to speed-up videos of clouds.


### How to build these tools?

- git clone this repositery
- install a D compiler and DUB the D build tool.
- chdir in the choosen tool directory
- type `dub` to build
- for better performance, type `dub -b release-nobounds` instead
- `shader-capture` needs SDL2 binaries to run


### How to use these tools?

All these tools use the standard input and output to allow piping.

```bash

$ y4m-tool -help

```

A Y4M can be encoded with ffmpeg with as an example the following line:

```
cat intput.y4m | ffmpeg -i - -vcodec libx264 -pix_fmt yuv420p -preset slow output.mp4
```

