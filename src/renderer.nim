import opengl
import x11/[xlib]
import la
import navigation
import flashlight

proc draw*(screenshot: PXImage, camera: Camera, shader, vao: GLuint, texture: GLuint,
           windowSize: Vec2f, mouse: Mouse, flashlight: Flashlight) =
  glClearColor(0.1, 0.1, 0.1, 1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

  glUseProgram(shader)

  glUniform2f(glGetUniformLocation(shader, "cameraPos".cstring), camera.position[0], camera.position[1])
  glUniform1f(glGetUniformLocation(shader, "cameraScale".cstring), camera.scale)
  glUniform2f(glGetUniformLocation(shader, "screenshotSize".cstring),
              screenshot.width.float32,
              screenshot.height.float32)
  glUniform2f(glGetUniformLocation(shader, "windowSize".cstring),
              windowSize.x.float32,
              windowSize.y.float32)
  glUniform2f(glGetUniformLocation(shader, "cursorPos".cstring),
              mouse.curr.x.float32,
              mouse.curr.y.float32)
  glUniform1f(glGetUniformLocation(shader, "flShadow".cstring), flashlight.shadow)
  glUniform1f(glGetUniformLocation(shader, "flRadius".cstring), flashlight.radius)

  glBindVertexArray(vao)
  glDrawElements(GL_TRIANGLES, count = 6, GL_UNSIGNED_INT, indices = nil)
