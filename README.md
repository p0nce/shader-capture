## What is `shader-capture`? 

`shader-capture` is a tool to turn a GLSL fragment shader into a raw video.
It is designed to work out-of-the-box with shaders made with [http://glslsandbox.com/](http://glslsandbox.com/)
The output video is Y4M using the Rec. 709 color space with no chroma-subsampling (4:4:4).

## How to build?

- git clone this repositery
- install a D compiler and DUB the D build tool.
- chdir in the cloned directory
- type `dub` to build
- for better performance, type `dub -b release-nobounds` instead


## How to use it?

```bash

$ shader-capture -help

Shader Capture

usage: shader-capture [-w 1920] [-h 1080] [-x 1] [-fps 60] [-duration 1] [-vs vertex.glsl] [-fs fragment.glsl] [-o output.y4m] [-h]


Arguments:
    -w     Sets width of output video (default: 1920).
    -h     Sets height of output video (default: 1080).
    -fps   Sets framerate of output video (default: 60).
    -x     Oversampling 1x 4x 16x or 64x (default: 1).
    -vs    Use this vertex shader (default: builtin shader)
    -fs    Use this vertex shader (default: fragment-shader.glsl)
    -o     Sets the output video filename (default: output.y4m)
    -help  Shows this help.

```

`shader-capture` comes with an example shader so that running it without arguments outputs a video.

The output can be encoded with ffmpeg with as an example the following line:

```
ffmpeg -i output.y4m -vcodec libx264 -preset slow -crf 18 -pix_fmt yuv420p output.mp4
```