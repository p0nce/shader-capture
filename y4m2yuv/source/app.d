import std.getopt,
       std.stdio,
       std.file;

import y4md;

void main(string[] args)
{
    if (args.length != 1)
    {
        stderr.writefln("Convert a Y4M file to a YUV file, keeping the chroma-subsampling.");
        stderr.writefln("Usage: cat input.y4m | y4m2yuv");
        return;
    }

    try
    {
        auto input = new Y4MReader(stdin);

        stderr.writefln("Input: %sx%s %sfps", input.width, input.height, cast(double)(input.framerate.num) / (input.framerate.denom));
        int numFrames = 0;
        ubyte[] frameBytes;
        while ( (frameBytes = input.readFrame()) !is null)
        {
            stderr.rawWrite(frameBytes);
            numFrames++;
        }

        stderr.writefln("Output %s frames", numFrames);
    }
    catch(Exception e)
    {
        writefln("%s", e.msg);
        return;
    }
}


