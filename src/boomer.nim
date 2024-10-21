import os

import x11/[xlib, x, xrandr]
import opengl, opengl/glx
import la

import navigation
import screenshot
import config
import shader
import x11error
import flashlight
import renderer
import window
import events
import glutils
import parseCLI

proc main() =
  let cliConfig = parseCliArgs()
  let configFilePath = cliConfig.configFile

  var config: Config
  if not fileExists(configFilePath):
    echo configFilePath, " doesn't exist. Generating default config."
    generateDefaultConfig(configFilePath)
  
  config = loadConfig(configFilePath)
  echo "Using config: ", config

  var display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"
  defer:
    discard XCloseDisplay(display)

  setX11ErrorHandler()

  when defined(select):
    echo "Please select window:"
    var trackingWindow = selectWindow(display)
  else:
    var trackingWindow = DefaultRootWindow(display)

  var screenConfig = XRRGetScreenInfo(display, DefaultRootWindow(display))
  let rate = XRRConfigCurrentRate(screenConfig)
  echo "Screen rate: ", rate

  let screen = XDefaultScreen(display)
  var glxMajor, glxMinor: cint
  if not glXQueryVersion(display, glxMajor, glxMinor).bool or
     (glxMajor == 1.cint and glxMinor < 3.cint) or
     (glxMajor < 1.cint):
    quit "Invalid GLX version. Expected >=1.3"
  
  echo("GLX version ", glxMajor, ".", glxMinor)
  echo("GLX extension: ", glXQueryExtensionsString(display, screen))

  let (win, vi) = createWindow(display, screen, cliConfig.windowed)
  let glc = glXCreateContext(display, vi, nil, GL_TRUE.cint)
  discard glXMakeCurrent(display, win, glc)

  loadExtensions()

  var shaderProgram = createShaderProgram(vertexShader, fragmentShader)

  var screenshot = newScreenshot(display, trackingWindow)
  defer: screenshot.destroy(display)

  var buffers = setupBuffers(screenshot.image.width.float32, screenshot.image.height.float32)
  defer:
    glDeleteVertexArrays(1, unsafeAddr buffers.vao)
    glDeleteBuffers(1, unsafeAddr buffers.vbo)
    glDeleteBuffers(1, unsafeAddr buffers.ebo)

  var texture = setupTexture(screenshot.image)

  var
    quitting = false
    camera = newCamera()
    mouse = newMouse(getCursorPosition(display))
    flashlight = newFlashlight()

  let dt = 1.0 / rate.float
  var originWindow: Window
  var revertToReturn: cint
  discard XGetInputFocus(display, addr originWindow, addr revertToReturn)

  while not quitting:
    if not cliConfig.windowed:
      discard XSetInputFocus(display, win, RevertToParent, CurrentTime)

    var wa: XWindowAttributes
    discard XGetWindowAttributes(display, win, addr wa)
    glViewport(0, 0, wa.width, wa.height)

    handleEvents(display, win, quitting, camera, mouse, flashlight, config, 
    shaderProgram, configFilePath)

    camera.update(config, dt, mouse, screenshot.image, vec2(wa.width.float32, wa.height.float32))
    flashlight.update(dt)

    renderer.draw(screenshot.image, camera, shaderProgram, buffers.vao, texture,
                  vec2(wa.width.float32, wa.height.float32), mouse, flashlight)

    glXSwapBuffers(display, win)
    glFinish()

    when defined(live):
      updateLiveScreenshot(display, trackingWindow, screenshot, vbo, texture)

  discard XSetInputFocus(display, originWindow, RevertToParent, CurrentTime)
  discard XSync(display, 0)

  cleanup(glc, win, display)

main()