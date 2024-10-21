import x11/[xlib, x]
import la

import config

const VELOCITY_THRESHOLD = 15.0

type 
  Mouse* = object
    curr*: Vec2f
    prev*: Vec2f
    drag*: bool

  Camera* = object
    position*: Vec2f
    velocity*: Vec2f
    scale*: float32
    deltaScale*: float32
    scalePivot*: Vec2f

proc newMouse*(initialPos: Vec2f): Mouse =
  Mouse(curr: initialPos, prev: initialPos, drag: false)

proc newCamera*(): Camera =
  Camera(
    position: vec2(0.0, 0.0),
    velocity: vec2(0.0, 0.0),
    scale: 1.0,
    deltaScale: 0.0,
    scalePivot: vec2(0.0, 0.0)
  )
proc world*(camera: Camera, v: Vec2f): Vec2f =
  v / camera.scale

proc update*(camera: var Camera, config: Config, dt: float, mouse: Mouse, image: PXImage, windowSize: Vec2f) =
  if abs(camera.deltaScale) > 0.5:
    let p0 = (camera.scalePivot - (windowSize * 0.5)) / camera.scale
    camera.scale = max(camera.scale + camera.delta_scale * dt, config.min_scale)
    let p1 = (camera.scalePivot - (windowSize * 0.5)) / camera.scale
    camera.position += p0 - p1

    camera.delta_scale -= camera.delta_scale * dt * config.scale_friction

  if not mouse.drag and (camera.velocity.length > VELOCITY_THRESHOLD):
    camera.position += camera.velocity * dt
    camera.velocity -= camera.velocity * dt * config.dragFriction



proc getCursorPosition*(display: PDisplay): Vec2f =
  var 
    root, child: Window
    root_x, root_y, win_x, win_y: cint
    mask: cuint

  discard XQueryPointer(
    display, 
    DefaultRootWindow(display),
    addr root, 
    addr child,
    addr root_x, 
    addr root_y,
    addr win_x, 
    addr win_y,
    addr mask
  )

  result.x = root_x.float32
  result.y = root_y.float32