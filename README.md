## Shader capture

### What is `shader-capture`?

`shader-capture` is a tool to turn a GLSL fragment shader into a raw video.
It is designed to work out-of-the-box with shaders made with [http://glslsandbox.com/](http://glslsandbox.com/)
The output video is Y4M using the Rec. 709 color space with no chroma-subsampling (4:4:4).

### How to build?

- git clone this repositery
- install a D compiler and DUB the D build tool.
- chdir in the cloned directory
- type `dub` to build
- for better performance, type `dub -b release-nobounds` instead
- the program needs SDL2 binaries to run


### How to use it?

```bash

$ shader-capture -help

```

The output can be encoded with ffmpeg with as an example the following line:

```
shader-capture.exe -w 1920 -h 1080 -fps 30 | ffmpeg -i - -vcodec libx264 -pix_fmt yuv420p -preset slow output.mp4
```

