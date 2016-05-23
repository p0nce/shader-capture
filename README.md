# shader-capture 

A simple tool to turn a shader into a Y4M raw video.
Designed to work out-of-the-box with shader made with [http://glslsandbox.com/](http://glslsandbox.com/)

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