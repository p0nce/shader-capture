import std.stdio;
import std.conv;
import std.string;

import y4md;



void usage()
{
    writeln();
    writeln("Shader Capture\n");
    writeln("usage: shader-capture [-width 1920] [-height 1080] [-fps 60] [-vs vertex-shader.glsl] [-fs fragment-shader.glsl] [-o output.y4m] [-h]\n");

}

void main(string[]args)
{
    try
    {
        int width = 1920;
        int height = 1080;
        double fps = 60;
        string vertexShaderFile = "vertex-shader.glsl";
        string fragmentShaderFile = "fragment-shader.glsl";
        string outputFile = "output.y4m";
        bool help = false;

        for(int i = 1; i < args.length; ++i)
        {
            string arg = args[i];
            if (arg == "-o")
            {               
                ++i;
                outputFile = args[i];
            }
            else if (arg == "-vs")
            {
                ++i;
                vertexShaderFile = args[i];
            }
            else if (arg == "-fs")
            {
                ++i;
                fragmentShaderFile = args[i];
            }         
            else if (arg == "-width")
            {
                ++i;
                width = to!int(args[i]);
            }
            else if (arg == "-height")
            {
                ++i;
                height = to!int(args[i]);
            }
            else if (arg == "-fps")
            {
                ++i;
                fps = to!double(args[i]);
            }
            else if (arg == "-h")
            {
                help = true;
            }
            else
               throw new Exception(format("Unknown argument '%s'", arg));
        }
        if (help)
        {
            usage();
            return;
        }


    }
    catch(Exception e)
    {
        import std.stdio;
        writefln("error: %s", e.msg);
        usage();
    }
}
