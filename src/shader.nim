import opengl
import os

type 
  Shader* = object
    path*: string
    content*: string

proc readShader*(file: string): Shader =
  when nimvm:
    result.path = "shaders" / file
    result.content = slurp(result.path)
  else:
    result.path = "shaders" / file
    result.content = readFile(result.path)

when defined(developer):
  var
    vertexShader* = readShader("vert.glsl")
    fragmentShader* = readShader("frag.glsl")

  proc reloadShader*(shader: var Shader) =
    shader.content = readFile(shader.path)
else:
  const
    vertexShader* = readShader("vert.glsl")
    fragmentShader* = readShader("frag.glsl")

proc compileShader*(shader: Shader, kind: GLenum): GLuint =
  result = glCreateShader(kind)
  var shaderArray = allocCStringArray([shader.content])
  glShaderSource(result, 1, shaderArray, nil)
  glCompileShader(result)
  deallocCStringArray(shaderArray)

  var success: GLint
  var infoLog = newString(512)
  glGetShaderiv(result, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(result, 512, nil, infoLog)
    echo "------------------------------"
    echo "Error during shader compilation: ", shader.path, ". Log:"
    echo infoLog
    echo "------------------------------"

proc createShaderProgram*(vertex, fragment: Shader): GLuint =
  result = glCreateProgram()

  let vertexShader = compileShader(vertex, GL_VERTEX_SHADER)
  let fragmentShader = compileShader(fragment, GL_FRAGMENT_SHADER)

  glAttachShader(result, vertexShader)
  glAttachShader(result, fragmentShader)
  glLinkProgram(result)

  glDeleteShader(vertexShader)
  glDeleteShader(fragmentShader)

  var success: GLint
  var infoLog = newString(512)
  glGetProgramiv(result, GL_LINK_STATUS, addr success)
  if success == 0:
    glGetProgramInfoLog(result, 512, nil, addr infoLog[0])
    echo infoLog

  glUseProgram(result)

proc useShaderProgram*(program: GLuint) =
  glUseProgram(program)

proc deleteShaderProgram*(program: GLuint) =
  glDeleteProgram(program)
