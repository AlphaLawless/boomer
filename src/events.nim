import x11/[xlib, x, keysym]
import opengl
import navigation
import config
import flashlight
import la
import os

const
  INITIAL_FL_DELTA_RADIUS = 250.0


proc handleScroll(isUp: bool, xev: XEvent, flashlight: var Flashlight, camera: var Camera, config: Config, mouse: Mouse) =
  if (xev.xkey.state and ControlMask) > 0.uint32 and flashlight.isEnabled:
    if isUp:
      flashlight.deltaRadius += INITIAL_FL_DELTA_RADIUS
    else:
      flashlight.deltaRadius -= INITIAL_FL_DELTA_RADIUS
  else:
    if isUp:
      camera.deltaScale += config.scrollSpeed
    else:
      camera.deltaScale -= config.scrollSpeed
    camera.scalePivot = mouse.curr

proc handleEvents*(display: PDisplay, win: Window, quitting: var bool, camera: var Camera, 
                   mouse: var Mouse, flashlight: var Flashlight, config: var Config, 
                   shaderProgram: var GLuint, configFilePath: string) =
  var xev: XEvent
  while XPending(display) > 0:
    discard XNextEvent(display, addr xev)

    case xev.theType
    of Expose:
      discard

    of MotionNotify:
      mouse.curr = vec2(xev.xmotion.x.float32, xev.xmotion.y.float32)

      if mouse.drag:
        let delta = world(camera, mouse.prev) - world(camera, mouse.curr)
        camera.position += delta
        camera.velocity = delta * 60.0 # Assumindo 60 FPS, ajuste se necessário

      mouse.prev = mouse.curr

    of ClientMessage:
      let wmDeleteMessage = XInternAtom(display, "WM_DELETE_WINDOW", XBool(false))
      if cast[Atom](xev.xclient.data.l[0]) == wmDeleteMessage:
        quitting = true

    of KeyPress:
      var key = XLookupKeysym(cast[PXKeyEvent](addr xev), 0)
      case key
      of XK_equal: handleScroll(true, xev, flashlight, camera, config, mouse)
      of XK_minus: handleScroll(false, xev, flashlight, camera, config, mouse)
      of XK_0:
        camera.scale = 1.0
        camera.deltaScale = 0.0
        camera.position = vec2(0.0, 0.0)
        camera.velocity = vec2(0.0, 0.0)
      of XK_q, XK_Escape:
        quitting = true
      of XK_r:
        if fileExists(configFilePath):
          config = loadConfig(configFilePath)
          echo "Configuração recarregada de ", configFilePath
        else:
          echo "Arquivo de configuração não encontrado. Gerando configuração padrão."
          generateDefaultConfig(configFilePath)
          config = loadConfig(configFilePath)
        when defined(developer):
          if (xev.xkey.state and ControlMask) > 0.uint32:
            echo "------------------------------"
            echo "RELOADING SHADERS"
            try:
              reloadShader(vertexShader)
              reloadShader(fragmentShader)
              let newShaderProgram = createShaderProgram(vertexShader, fragmentShader)
              glDeleteProgram(shaderProgram)
              shaderProgram = newShaderProgram
              echo "Shader program ID: ", shaderProgram
            except GLerror:
              echo "Could not reload the shaders"
            echo "------------------------------"
      of XK_f:
        flashlight.isEnabled = not flashlight.isEnabled
      else:
        discard

    of ButtonPress:
      case xev.xbutton.button
      of Button1:
        mouse.prev = mouse.curr
        mouse.drag = true
        camera.velocity = vec2(0.0, 0.0)
      of Button4: handleScroll(true, xev, flashlight, camera, config, mouse)
      of Button5: handleScroll(false, xev, flashlight, camera, config, mouse)
      else:
        discard

    of ButtonRelease:
      case xev.xbutton.button
      of Button1:
        mouse.drag = false
      else:
        discard
    else:
      discard