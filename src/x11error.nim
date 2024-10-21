import x11/xlib

const CAPACITY = 256

proc xElevenErrorHandler*(display: PDisplay, errorEvent: PXErrorEvent): cint {.cdecl.} =
  var errorMessage: array[CAPACITY, char]
  discard XGetErrorText(
    display, 
    errorEvent.error_code.cint, 
    cast[cstring](addr errorMessage), 
    CAPACITY
  )
  echo "X11 ERROR: ", $(cast[cstring](addr errorMessage))
  return 0  # Retornando 0 para indicar que o erro foi tratado

proc setX11ErrorHandler*() =
  discard XSetErrorHandler(xElevenErrorHandler)
