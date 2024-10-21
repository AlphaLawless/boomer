import x11/[xlib, x, cursorfont, xutil]
import opengl/glx

type WindowInfo = tuple[win: Window, vi: PXVisualInfo]

proc selectWindow*(display: PDisplay): Window =
  var cursor = XCreateFontCursor(display, XC_crosshair)
  defer: discard XFreeCursor(display, cursor)

  var root = DefaultRootWindow(display)
  discard XGrabPointer(display, root, 0,
                       ButtonMotionMask or
                       ButtonPressMask or
                       ButtonReleaseMask,
                       GrabModeAsync, GrabModeAsync,
                       root, cursor,
                       CurrentTime)
  defer: discard XUngrabPointer(display, CurrentTime)

  discard XGrabKeyboard(display, root, 0,
                        GrabModeAsync, GrabModeAsync,
                        CurrentTime)
  defer: discard XUngrabKeyboard(display, CurrentTime)

  var event: XEvent
  while true:
    discard XNextEvent(display, addr event)
    case event.theType
    of ButtonPress:
      return event.xbutton.subwindow
    of KeyPress:
      return root
    else:
      discard

  return root

proc createWindow*(display: PDisplay, screen: cint, windowed: bool): WindowInfo =
  var attrs = [
    GLX_RGBA,
    GLX_DEPTH_SIZE, 24,
    GLX_DOUBLEBUFFER,
    None
  ]

  var vi = glXChooseVisual(display, 0, addr attrs[0])
  if vi == nil:
    quit "No appropriate visual found"

  echo "Visual ", vi.visualid, " selected"
  var swa: XSetWindowAttributes
  swa.colormap = XCreateColormap(display, DefaultRootWindow(display),
                                 vi.visual, AllocNone)
  swa.event_mask = ButtonPressMask or ButtonReleaseMask or
                   KeyPressMask or KeyReleaseMask or
                   PointerMotionMask or ExposureMask or ClientMessage
  if not windowed:
    swa.override_redirect = 1
    swa.save_under = 1

  var attributes: XWindowAttributes
  discard XGetWindowAttributes(
    display,
    DefaultRootWindow(display),
    addr attributes)
  
  var win = XCreateWindow(
    display, DefaultRootWindow(display),
    0, 0, attributes.width.cuint, attributes.height.cuint, 0,
    vi.depth, InputOutput, vi.visual,
    CWColormap or CWEventMask or CWOverrideRedirect or CWSaveUnder, addr swa)

  discard XMapWindow(display, win)

  var wmName: cstring = "boomer"
  var wmClass: cstring = "Boomer"
  var hints = XClassHint(res_name: wmName, res_class: wmClass)

  discard XStoreName(display, win, wmName)
  discard XSetClassHint(display, win, addr(hints))

  var wmDeleteMessage = XInternAtom(
    display, "WM_DELETE_WINDOW",
    0.cint)

  discard XSetWMProtocols(display, win,
                          addr wmDeleteMessage, 1)

  return (win, vi)

proc cleanup*(glc: GLXContext, win: Window, display: PDisplay) =
  # Desvincula o contexto OpenGL atual
  discard glXMakeCurrent(display, None, nil)
  
  # Destrói o contexto OpenGL
  glXDestroyContext(display, glc)
  
  # Destrói a janela X11
  discard XDestroyWindow(display, win)
  
  # Fecha a conexão com o servidor X
  discard XCloseDisplay(display)
