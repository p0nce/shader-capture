import std.stdio;
import std.conv;
import std.file;
import std.string;
import std.typecons;

import core.thread;

import y4md;

void usage()
{
    stderr.writeln();
    stderr.writeln("Merge Frames\n");
    stderr.writeln("usage: cat input.y4m | merge-capture [-n 10] > output.y4m [-h]\n");
    stderr.writeln();
    stderr.writeln("Arguments:");
    stderr.writeln("    -n Number     Each set of Number frames are averaged (default: 2)");
    stderr.writeln("    -help         Shows this help.");
    stderr.writeln();
}

int main(string[]args)
{
    try
    {
        int N = 2;
        bool help = false;

        for(int i = 1; i < args.length; ++i)
        {
            string arg = args[i];
            if (arg == "-n")
            {
                ++i;
                N = to!int(args[i]);
            }
            else if (arg == "-help")
            {
                help = true;
            }
            else
               throw new Exception(format("Unknown argument '%s'", arg));
        }
        if (help)
        {
            usage();
            return 0;
        }

        auto y4mInput = new Y4MReader(stdin);

        int width = y4mInput.width;
        int height = y4mInput.height;
        Rational framerate = y4mInput.framerate;
        Rational pixelAR = y4mInput.pixelAR;
        Interlacing interlacing = y4mInput.interlacing;
        Subsampling subsampling = y4mInput.subsampling;
        int bitdepth = y4mInput.bitdepth;

        auto y4mOutput = new Y4MWriter(stdout, width, height, y4mInput.framerate, y4mInput.pixelAR, interlacing, subsampling); 
        ubyte[] frameBytes = new ubyte[y4mOutput.frameSize()];

        assert(y4mInput.frameSize() == y4mOutput.frameSize());

        size_t frameBytes = y4mInput.frameSize();

        ubyte[][] framesIn;

        ubyte[] frameOut;

        framesIn.length = N;
        foreach(i; 0..N)
        {
            framesIn[i].length = frameBytes;
        }
        frameOut.length = frameBytes;

        mainloop: while (true)
        {
            // Try to read N frames from input
            foreach(i; 0..N)
            {
                ubyte[] frameData = y4mInput.readFrame();
                if (frameData is null)
                    break mainloop; // not enough frame to merge
                framesIn[i][] = frameData[]; // copy
            }

            foreach (b; 0..frameBytes)
            {
                int total = 0;
                foreach(i; 0..N)
                {
                    total

                }
            }

            output.writeFrame(frameOut[]);
        }

        return 0;
    }
    catch(Exception e)
    {
        import std.stdio;
        stderr.writefln("error: %s", e.msg);
        usage();
        return 1;
    }
}
