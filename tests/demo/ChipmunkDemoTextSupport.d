/*
 * Copyright (c) 2007-2013 Scott Lembcke and Howling Moon Software
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module demo.ChipmunkDemoTextSupport;

import glad.gl.all;

import demo.dchip;

import demo.ChipmunkDemoShaderSupport;
import demo.VeraMoBd_ttf_sdf;
import demo.types;

void ChipmunkDemoTextInit();

//#define ChipmunkDemoTextDrawString(...)

//#define Scale 3.0f
enum Scale = 0.70f;
enum LineHeight = 18.0f * Scale;

GLuint program;
GLuint texture;

struct v2f
{
    GLfloat x, y;
}

struct Vertex
{
    v2f vertex, tex_coord;
    Color color;
}

struct Triangle
{
    Vertex a, b, c;
}

GLuint vao = 0;
GLuint vbo = 0;

// char -> glyph indexes generated by the lonesock tool.
int[256] glyph_indexes;

void ChipmunkDemoTextInit()
{
    GLint vshader = CompileShader(GL_VERTEX_SHADER,
        q{
            attribute vec2 vertex;
            attribute vec2 tex_coord;
            attribute vec4 color;

            varying vec2 v_tex_coord;
            varying vec4 v_color;

            void main(){
                // TODO get rid of the GL 2.x matrix bit eventually?
                gl_Position = gl_ModelViewProjectionMatrix * vec4(vertex, 0.0, 1.0);

                v_color = color;
                v_tex_coord = tex_coord;
            }
        });

    GLint fshader = CompileShader(GL_FRAGMENT_SHADER,
        q{
            uniform sampler2D u_texture;

            varying vec2 v_tex_coord;
            varying vec4 v_color;

            float aa_step(float t1, float t2, float f)
            {
                //return step(t2, f);
                return smoothstep(t1, t2, f);
            }

            void main()
            {
                float sdf = texture2D(u_texture, v_tex_coord).a;

                //float fw = fwidth(sdf)*0.5;
                float fw = length(vec2(dFdx(sdf), dFdy(sdf))) * 0.5;

                float alpha = aa_step(0.5 - fw, 0.5 + fw, sdf);
                gl_FragColor = v_color * (v_color.a * alpha);

                //			gl_FragColor = vec4(1, 0, 0, 1);
            }
        });

    program = LinkProgram(vshader, fshader);
    CHECK_GL_ERRORS();

    //	GLint index = -1;//glGetUniformLocation(program, "u_texture");
    //	glUniform1i(index, 0);
    //	CHECK_GL_ERRORS();

    // Setu VBO and VAO.
    version (OSX)
    {
        glGenVertexArraysAPPLE(1, &vao);
        glBindVertexArrayAPPLE(vao);
    }
    else
    {
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);
    }

    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);

    mixin(SET_ATTRIBUTE("program", "Vertex", "vertex", "GL_FLOAT"));
    mixin(SET_ATTRIBUTE("program", "Vertex", "tex_coord", "GL_FLOAT"));
    mixin(SET_ATTRIBUTE("program", "Vertex", "color", "GL_FLOAT"));

    glBindBuffer(GL_ARRAY_BUFFER, 0);

    version (OSX)
    {
        glBindVertexArrayAPPLE(0);
    }
    else
    {
        glBindVertexArray(0);
    }

    CHECK_GL_ERRORS();

    // Load the SDF font texture.
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, sdf_tex_width, sdf_tex_height, 0, GL_ALPHA, GL_UNSIGNED_BYTE, sdf_data.ptr);
    glGenerateMipmap(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    CHECK_GL_ERRORS();

    // Fill in the glyph index array.
    for (int i = 0; i < sdf_num_chars; i++)
    {
        int char_index = sdf_spacing[i * 8];
        glyph_indexes[char_index] = i;
    }
}

auto MAX(T)(T a, T b)
{
    return a > b ? a : b;
}

size_t triangle_capacity = 0;
size_t triangle_count     = 0;
Triangle* triangle_buffer = null;

Triangle* PushTriangles(size_t count)
{
    if (triangle_count + count > triangle_capacity)
    {
        triangle_capacity += MAX(triangle_capacity, count);
        triangle_buffer    = cast(Triangle*)realloc(triangle_buffer, triangle_capacity * Triangle.sizeof);
    }

    Triangle* buffer = triangle_buffer + triangle_count;
    triangle_count += count;
    return buffer;
}

GLfloat PushChar(int character, GLfloat x, GLfloat y, Color color)
{
    int i     = glyph_indexes[character];
    GLfloat w = cast(GLfloat)sdf_tex_width;
    GLfloat h = cast(GLfloat)sdf_tex_height;

    GLfloat gw = cast(GLfloat)sdf_spacing[i * 8 + 3];
    GLfloat gh = cast(GLfloat)sdf_spacing[i * 8 + 4];

    GLfloat txmin = sdf_spacing[i * 8 + 1] / w;
    GLfloat tymin = sdf_spacing[i * 8 + 2] / h;
    GLfloat txmax = txmin + gw / w;
    GLfloat tymax = tymin + gh / h;

    GLfloat s    = Scale / scale_factor;
    GLfloat xmin = x + sdf_spacing[i * 8 + 5] / scale_factor * Scale;
    GLfloat ymin = y + (sdf_spacing[i * 8 + 6] / scale_factor - gh) * Scale;
    GLfloat xmax = xmin + gw * Scale;
    GLfloat ymax = ymin + gh * Scale;

    Vertex a = { { xmin, ymin }, { txmin, tymax }, color };
    Vertex b = { { xmin, ymax }, { txmin, tymin }, color };
    Vertex c = { { xmax, ymax }, { txmax, tymin }, color };
    Vertex d = { { xmax, ymin }, { txmax, tymax }, color };

    Triangle* triangles = PushTriangles(2);
    Triangle  t0        = { a, b, c };
    triangles[0] = t0;
    Triangle t1 = { a, c, d };
    triangles[1] = t1;

    return sdf_spacing[i * 8 + 7] * s;
}

void ChipmunkDemoTextDrawString(cpVect pos, in char[] str)
{
    //~ Color c   = LAColor(1.0f, 1.0f);
    //~ GLfloat x = cast(GLfloat)pos.x, y = cast(GLfloat)pos.y;

    //~ for (int i = 0, len = str.length; i < len; i++)
    //~ {
        //~ if (str[i] == '\n')
        //~ {
            //~ y -= LineHeight;
            //~ x  = cast(GLfloat)pos.x;

            //~ //		} else if(str[i] == '*'){ // print out the last demo key
            //~ //			glutBitmapCharacter(GLUT_BITMAP_HELVETICA_10, 'A' + demoCount - 1);
        //~ }
        //~ else
        //~ if (str[i] == '\0')
        //~ {
            //~ break;
        //~ }
        //~ else
        //~ {
            //~ x += cast(GLfloat)PushChar(str[i], x, y, c);
        //~ }
    //~ }
}

void ChipmunkDemoTextFlushRenderer()
{
    //	triangle_count = 0;
    //	ChipmunkDemoTextDrawString(cpv(-300, 0), "0.:,'");

    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, Triangle.sizeof * triangle_count, triangle_buffer, GL_STREAM_DRAW);

    glUseProgram(program);

    version (OSX)
    {
        glBindVertexArrayAPPLE(vao);
    }
    else
    {
        glBindVertexArray(vao);
    }

    glDrawArrays(GL_TRIANGLES, 0, triangle_count * 3);

    CHECK_GL_ERRORS();
}

void ChipmunkDemoTextClearRenderer()
{
    triangle_count = 0;
}

int pushed_triangle_count = 0;

void ChipmunkDemoTextPushRenderer()
{
    pushed_triangle_count = triangle_count;
}

void ChipmunkDemoTextPopRenderer()
{
    triangle_count = pushed_triangle_count;
}