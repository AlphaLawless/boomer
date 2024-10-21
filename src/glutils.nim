import opengl
import x11/[xlib]  # PXImage

type BufferObjects = tuple[vao, vbo, ebo: GLuint]

proc setupBuffers*(width, height: float32): BufferObjects =
  var
    vao, vbo, ebo: GLuint
    vertices = [
      # Position                 Texture coords
      GLfloat(width),     0'f32, 0'f32, 1'f32, 1'f32, # Top right
      GLfloat(width), height, 0'f32, 1'f32, 0'f32, # Bottom right
      0'f32,     height, 0'f32, 0'f32, 0'f32, # Bottom left
      0'f32,     0'f32, 0'f32, 0'f32, 1'f32  # Top left
    ]
    indices = [GLuint(0), 1, 3,
                      1,  2, 3]

  glGenVertexArrays(1, addr vao)
  glGenBuffers(1, addr vbo)
  glGenBuffers(1, addr ebo)

  glBindVertexArray(vao)

  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBufferData(GL_ARRAY_BUFFER, size = GLsizeiptr(sizeof(vertices)),
               addr vertices, GL_STATIC_DRAW)

  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, size = GLsizeiptr(sizeof(indices)),
               addr indices, GL_STATIC_DRAW)

  var stride = GLsizei(5 * sizeof(GLfloat))

  glVertexAttribPointer(0, 3, cGL_FLOAT, false, stride, cast[pointer](0))
  glEnableVertexAttribArray(0)

  glVertexAttribPointer(1, 2, cGL_FLOAT, false, stride, cast[pointer](3 * sizeof(GLfloat)))
  glEnableVertexAttribArray(1)

  result = (vao, vbo, ebo)

proc setupTexture*(image: PXImage): GLuint =
  var texture: GLuint
  glGenTextures(1, addr texture)
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, texture)

  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGB.GLint,
               image.width,
               image.height,
               0,
               GL_BGRA,
               GL_UNSIGNED_BYTE,
               image.data)
  glGenerateMipmap(GL_TEXTURE_2D)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER)

  result = texture