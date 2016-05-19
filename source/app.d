import std.stdio;
import std.conv;
import std.string;
import std.typecons;

import y4md;

import gfm.sdl2,
       gfm.opengl,
       gfm.logger,
       gfm.math;




void usage()
{
    writeln();
    writeln("Shader Capture\n");
    writeln("usage: shader-capture [-width 1920] [-height 1080] [-fps 60] [-duration 1] [-vs vertex-shader.glsl] [-fs fragment-shader.glsl] [-o output.y4m] [-h]\n");

}

void main(string[]args)
{
    try
    {
        int width = 1920;
        int height = 1080;
        int fps = 60;
        string vertexShaderFile = "vertex-shader.glsl";
        string fragmentShaderFile = "fragment-shader.glsl";
        string outputFile = "output.y4m";
        double durationInSecs = 1;
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
                fps = to!int(args[i]);
            } else if (arg == "-duration")
            {
                ++i;
                durationInSecs = to!double(args[i]);
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

        int numFrames = cast(int)(0.5 + durationInSecs * fps);

        auto y4mOutput = new Y4MWriter(outputFile, width, height, Rational(fps, 1)); 
        ubyte[] frameBytes = new ubyte[y4mOutput.frameSize()];


        auto window = new CaptureWindow(width, height);
        scope(exit) window.destroy();

        int iFrame = 0;

        for (; iFrame < numFrames; ++iFrame)
        {
            window.processEvents();

            if (window.wasQuitRequested())
                break;

            // write something in frameData...

            double time = iFrame / fps;

            window.displayFrame(time);

            y4mOutput.writeFrame(frameBytes[]);
        }

        writefln("Written %s frames to %s.", iFrame, outputFile); 
    }
    catch(Exception e)
    {
        import std.stdio;
        writefln("error: %s", e.msg);
        usage();
    }
}


class CaptureWindow
{
    this(int width, int height)
    {
        // create a coloured console logger
        _log = new ConsoleLogger();

        // load dynamic libraries
        _sdl2 = new SDL2(_log, SharedLibVersion(2, 0, 0));
        _gl = new OpenGL(_log);

        // You have to initialize each SDL subsystem you want by hand
        _sdl2.subSystemInit(SDL_INIT_VIDEO);
        _sdl2.subSystemInit(SDL_INIT_EVENTS);

        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

        // create an OpenGL-enabled SDL window
        _window = new SDL2Window(_sdl2,
                                 SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                 720, 576,
                                 SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);

        // reload OpenGL now that a context exists
        _gl.reload();

        _texture = new GLTexture2D(_gl);
        _texture.setMinFilter(GL_LINEAR_MIPMAP_LINEAR);
        _texture.setMagFilter(GL_LINEAR);
        _texture.setImage(0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null); 
        _texture.generateMipmap();
    }

    ~this()
    {
        _texture.destroy();
        _window.destroy();
        _gl.destroy();
        _sdl2.destroy();
        _log.destroy();
    }

    void processEvents()
    {
        _sdl2.processEvents();
    }

    bool wasQuitRequested()
    {
        return _sdl2.wasQuitRequested();
    }

    void displayFrame(double time)
    {
        glClearColor(0.5f, 0.5f, 0.5f, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        recomputeTextureContent(time);
        drawTextureContent();
        _window.swapBuffers();
    }

    void recomputeTextureContent(double time)
    {
        // TODO draw shader
    }

    void drawTextureContent()
    {
        // TODO draw shader
    }

    ConsoleLogger _log;
    SDL2 _sdl2;
    OpenGL _gl;
    SDL2Window _window;

    GLTexture2D _texture;
}