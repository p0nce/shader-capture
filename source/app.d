import std.stdio;
import std.conv;
import std.file;
import std.string;
import std.typecons;

import core.thread;

import y4md;

import gfm.sdl2,
       gfm.opengl,
       gfm.logger,
       gfm.math;




void usage()
{
    writeln();
    writeln("Shader Capture\n");
    writeln("usage: shader-capture [-w 1920] [-h 1080] [-x 1] [-fps 60] [-duration 1] [-vs vertex.glsl] [-fs fragment.glsl] [-o output.y4m] [-h]\n");
    writeln();
    writeln("Arguments:");
    writeln("    -w     Sets width of output video (default: 1920).");
    writeln("    -h     Sets height of output video (default: 1080).");
    writeln("    -fps   Sets framerate of output video (default: 60).");
    writeln("    -x     Oversampling 1x 4x 16x or 64x (default: 1).");
    writeln("    -vs    Use this vertex shader (default: builtin shader)");
    writeln("    -fs    Use this vertex shader (default: fragment-shader.glsl)");
    writeln("    -o     Sets the output video filename (default: output.y4m)");
    writeln("    -help  Shows this help.");
    writeln();
}

enum Oversampling
{
    x1 = 0,   // scene is rendered at 1x resolution (default)
    x4 = 1,   // scene is rendered at 2x resolution
    x16 = 2,  // scene is rendered at 4x resolution
    x64 = 3,  // scene is rendered at 8x resolution
}

int oversamplingToScale(Oversampling o)
{
    return 1 << o;
}

void main(string[]args)
{
    try
    {
        int width = 1920;
        int height = 1080;
        int fps = 60;
        string vertexShaderFile = null;
        string fragmentShaderFile = "fragment-shader.glsl";
        string outputFile = "output.y4m";
        double durationInSecs = 1;
        bool help = false;
        Oversampling oversampling = Oversampling.x1;

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
            else if (arg == "-w")
            {
                ++i;
                width = to!int(args[i]);
            }
            else if (arg == "-h")
            {
                ++i;
                height = to!int(args[i]);
            }
            else if (arg == "-x")
            {
                ++i;
                int scale = to!int(args[i]);
                switch(scale)
                {
                    case 1: oversampling = Oversampling.x1; break;
                    case 4: oversampling = Oversampling.x4; break;
                    case 16: oversampling = Oversampling.x16; break;
                    case 64: oversampling = Oversampling.x64; break;
                    default:
                        throw new Exception("Accepted -x values: 1, 4, 16, 64");
                }
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
            else if (arg == "-help" || arg == "--help")
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

        auto y4mOutput = new Y4MWriter(outputFile, width, height, Rational(fps, 1), Rational(1, 1), Interlacing.Progressive, Subsampling.C444); 
        ubyte[] frameBytes = new ubyte[y4mOutput.frameSize()];


        auto window = new CaptureWindow(width, height, oversampling, vertexShaderFile, fragmentShaderFile);
        scope(exit) window.destroy();

        int iFrame = 0;

        for (; iFrame < numFrames; ++iFrame)
        {
            window.processEvents();

            if (window.wasQuitRequested())
                break;

            // write something in frameData...

            double time = iFrame / cast(double)fps;

            window.displayFrame(time);
            window.getFrameContentYUV444(frameBytes[]);
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


struct Vertex
{
    vec3f position;
}


class CaptureWindow
{
    this(int width, int height, Oversampling oversampling, string vertexShaderFile, string fragmentShaderFile)
    {
        _captureWidth = width;
        _captureHeight = height;

        _renderWidth = width * oversamplingToScale(oversampling);
        _renderHeight = height * oversamplingToScale(oversampling);

        // which level of mipmap to read back?
        _levelReadback = oversampling;

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
        _texture.setWrapS(GL_CLAMP_TO_EDGE);
        _texture.setWrapT(GL_CLAMP_TO_EDGE);
        _texture.setImage(0, GL_RGBA, _renderWidth, _renderHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, null); 
        _texture.generateMipmap();    

        _fbo = new GLFBO(_gl);
        _fbo.use();
        _fbo.color(0).attach(_texture);
        _fbo.unuse();

        _blitProgram = new GLProgram(_gl, blitProgramSource);

        // Create shaders
        string vertexShaderSource;
        string fragmentShaderSource = cast(string) read(fragmentShaderFile);

        if (vertexShaderFile != null && exists(vertexShaderFile))
        {
            vertexShaderSource = cast(string) read(vertexShaderFile);
        }
        else
        {
            writeln("No existing vertex shader provided, using a default one.");
            vertexShaderSource = defaultVertexShader;
        }

        // ensure first line is "#version" 
        // Default is #version 110 which seems in line with what online shaders do
        if (fragmentShaderSource.length < 9 || fragmentShaderSource[0..9] != "#version ")
            fragmentShaderSource = "#version 110\n" ~ fragmentShaderSource;
        if (vertexShaderSource.length < 9 || vertexShaderSource[0..9] != "#version ")
            vertexShaderSource = "#version 110\n" ~ vertexShaderSource;


        {
            auto vertexShader = new GLShader(_gl, GL_VERTEX_SHADER, splitLines(vertexShaderSource));
            scope(exit) vertexShader.destroy();
            auto fragmentShader = new GLShader(_gl, GL_FRAGMENT_SHADER, splitLines(fragmentShaderSource));
            scope(exit) fragmentShader.destroy();
            _sceneProgram = new GLProgram(_gl, [vertexShader, fragmentShader]);
        }
        createGeometry();

        _rgbaBuf.length = _captureWidth * _captureHeight * 4;
    }

    ~this()
    {
        _fbo.destroy();
        _sceneProgram.destroy();
        _blitProgram.destroy();
        _vao.destroy();
        _quadVBO.destroy();
        _quadVS.destroy();

        _texture.destroy();
        _window.destroy();
        _gl.destroy();
        _sdl2.destroy();
        _log.destroy();
    }

    void createGeometry()
    { 

        Vertex[] quad;
        quad ~= Vertex(vec3f(-1, -1, 0));
        quad ~= Vertex(vec3f(+1, -1, 0));
        quad ~= Vertex(vec3f(+1, +1, 0));
        quad ~= Vertex(vec3f(+1, +1, 0));
        quad ~= Vertex(vec3f(-1, +1, 0));
        quad ~= Vertex(vec3f(-1, -1, 0));

        _quadVBO = new GLBuffer(_gl, GL_ARRAY_BUFFER, GL_STATIC_DRAW, quad[]);
        _quadVS = new VertexSpecification!Vertex(_blitProgram);
        _vao = new GLVAO(_gl);

        // prepare VAO
        {
            _vao.bind();
            _quadVBO.bind();
            _quadVS.use();
            _vao.unbind();
        }
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
        SDL_Point size = _window.getSize();

        glViewport(0, 0, size.x, size.y); // TODO adapt to current window dimension
        glClearColor(0.5f, 0.5f, 0.5f, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        recomputeTextureContent(time);
        drawTextureContent(size.x, size.y);
    }

    void recomputeTextureContent(double time) 
    {
        glViewport(0, 0, _renderWidth, _renderHeight); 
        _fbo.use();

        // variables from http://glslsandbox.com/
        _sceneProgram.uniform("time").set!float(time);
        _sceneProgram.uniform("resolution").set( vec2f(_renderWidth, _renderHeight) );
        _sceneProgram.uniform("mouse").set(vec2f(_renderWidth * 0.5f, _renderHeight * 0.5f)); // middle of screen TODO move it?

        _sceneProgram.use();
        drawFullQuad();
        _sceneProgram.unuse();

        _fbo.unuse();

        // this step allow mipmapped display, and also does the subsampling for readback
        _texture.generateMipmap(); 
    }

    /// Shows the content of texture into the displayed framebuffer
    void drawTextureContent(int displayWidth, int displayHeight)
    {
        int texUnit = 1;
        _texture.use(texUnit);

        _blitProgram.uniform("fbTexture").set(texUnit);
        _blitProgram.uniform("captureSize").set(vec2f(_captureWidth, _captureHeight));
        _blitProgram.uniform("displaySize").set(vec2f(displayWidth, displayHeight));
        _blitProgram.use();
        drawFullQuad();
        _blitProgram.unuse();

        _window.swapBuffers();
    }

    /// Gets texture content, and convert it to YUV444 using BT 701 conversion
    void getFrameContentYUV444(ubyte[] frame)
    {
        int numPixels = _captureWidth * _captureHeight;
        assert(frame.length == numPixels * 3);
        
        // read back texture

        _texture.getTexImage(_levelReadback, GL_RGBA, GL_UNSIGNED_BYTE, _rgbaBuf.ptr);
        

        // Convert from interlaced RGBA8 to planar YUV 4:4:4
        // using Rec 709 everytime (should be 601 for SD video but unimplemented)

        ubyte* baseY = frame.ptr;
        ubyte* baseU = frame.ptr + numPixels;
        ubyte* baseV = frame.ptr + 2 * numPixels;

        foreach (int y; 0.._captureHeight)
        {
            foreach (int x; 0.._captureWidth)
            {
                int index = ((_captureHeight - 1 - y) * _captureWidth + x) * 4;  // flip vertically
                int R = _rgbaBuf[index + 0];
                int G = _rgbaBuf[index + 1];
                int B = _rgbaBuf[index + 2];
                int A = _rgbaBuf[index + 3];

                int Y = cast(int)(0.5f + 0.213f*R + 0.715f*G + 0.072f*B);
                int Cb = cast(int)(0.5f + -0.117f*R - 0.394f*G + 0.511f*B + 128);
                int Cr = cast(int)(0.5f + 0.511f*R - 0.464f*G - 0.047f*B + 128);

                if (Y < 16) Y = 16;
                if (Y > 235) Y = 235;
                if (Cb < 16) Cb = 16;
                if (Cb > 240) Cb = 240;
                if (Cr < 16) Cr = 16;
                if (Cr > 240) Cr = 240;

                int outI = (y * _captureWidth + x);
                baseY[outI] = cast(ubyte)Y;
                baseU[outI] = cast(ubyte)Cb;
                baseV[outI] = cast(ubyte)Cr;
            }
        }
    }

    void drawFullQuad()
    {
        _vao.bind();
        glDrawArrays(GL_TRIANGLES, 0, cast(int)(_quadVBO.size() / _quadVS.vertexSize()));
        _vao.unbind();
    }
    

    ConsoleLogger _log;
    SDL2 _sdl2;
    OpenGL _gl;
    SDL2Window _window;

    GLTexture2D _texture;

    GLBuffer _quadVBO;
    VertexSpecification!Vertex _quadVS;
    GLVAO _vao;

    GLFBO _fbo;

    GLProgram _sceneProgram;
    GLProgram _blitProgram;

    // The size of the video wen displayed, and captured as video.
    int _captureWidth;
    int _captureHeight;

    // The size of the video effectively rendered by the shader.
    // Is a pow2 multiple of the capture size because of oversampling.
    int _renderWidth;
    int _renderHeight;

    // which level of mipmap to read back?
    int _levelReadback;

    ubyte[] _rgbaBuf;
}

string blitProgramSource =
q{#version 330 core

    #if VERTEX_SHADER
    in vec3 position;
    void main()
    {
        gl_Position = vec4(position, 1.0);
    }
    #endif

    #if FRAGMENT_SHADER
    uniform sampler2D fbTexture;
    uniform vec2 displaySize;
    uniform vec2 captureSize;
    out vec4 color;

    void main()
    {
        float displayRatio = displaySize.x / displaySize.y;
        float captureRatio = captureSize.x / captureSize.y;
        vec2 screenPos = ( gl_FragCoord.xy / displaySize.xy );

        vec2 uv = screenPos;

        color = texture(fbTexture, uv).rgba; // stretch TODO proper ratio display
    }
    #endif
};

string defaultVertexShader =
    q{#version 330 core

        in vec3 position;
        void main()
        {
            gl_Position = vec4(position, 1.0);
        }
    };

