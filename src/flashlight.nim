type Flashlight* = object
  isEnabled*: bool
  shadow*: float32
  radius*: float32
  deltaRadius*: float32

const
  INITIAL_FL_DELTA_RADIUS* = 250.0
  FL_DELTA_RADIUS_DECELERATION* = 10.0

proc update*(flashlight: var Flashlight, dt: float32) =
  if abs(flashlight.deltaRadius) > 1.0:
    flashlight.radius = max(0.0, flashlight.radius + flashlight.deltaRadius * dt)
    flashlight.deltaRadius -= flashlight.deltaRadius * FL_DELTA_RADIUS_DECELERATION * dt

  if flashlight.isEnabled:
    flashlight.shadow = min(flashlight.shadow + 6.0 * dt, 0.8)
  else:
    flashlight.shadow = max(flashlight.shadow - 6.0 * dt, 0.0)

proc newFlashlight*(radius: float32 = 200.0): Flashlight =
  Flashlight(isEnabled: false, radius: radius)
