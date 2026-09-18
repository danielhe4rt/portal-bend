import Base

# Game constants: window, camera, physics, portals and palette.

# ===== Window and camera =====

# Initial window size. The tiling manager can change it later.
def W() -> U32:
  1280

def H() -> U32:
  720

# Reference screen (720 rows): pitch and aim use this screen.
# In a window of height h, the game multiplies these values by h / 720.
def HALF_H() -> F32:
  360.0

def REF_H() -> F32:
  720.0

# Height in pixels of a wall at distance 1, on the reference screen.
def SCALE() -> F32:
  800.0

# ===== Rays =====

def FUEL() -> Nat:
  40n

# Maximum number of portals that one ray goes through. The next portal shows as closed.
def PASSES() -> Nat:
  8n

# ===== Physics =====

def ACCEL() -> F32:
  0.012

def AIR_ACCEL() -> F32:
  0.0025

def FRICTION() -> F32:
  0.85

def AIR_FRICTION() -> F32:
  0.985

def GRAVITY() -> F32:
  0.003

def JUMP() -> F32:
  0.046

def Z_MAX() -> F32:
  0.38

def MAX_SPEED() -> F32:
  0.12

def RADIUS() -> F32:
  0.22

# ===== Portals =====

# Radii of the portal ellipse, as fractions of the cell (width) and of the wall (height).
def PORTAL_RX() -> F32:
  0.40

def PORTAL_RY() -> F32:
  0.46

# Minimum speed out of the wall immediately after a crossing.
def EXIT_SPEED() -> F32:
  0.035

def FUNNEL() -> F32:
  0.012

def FUNNEL_REACH() -> F32:
  1.6

# ===== Camera and input =====

def TURN() -> F32:
  0.045

def PITCH_RATE() -> F32:
  9.0

def PITCH_MAX() -> F32:
  300.0

# Turn and tilt for each pixel of mouse movement.
def YAW_PER_PX() -> F32:
  0.004

def PITCH_PER_PX() -> F32:
  1.6

def CLOCK_RATE() -> F32:
  0.09

# ===== Player body, seen through the portals =====

def BODY_HALF() -> F32:
  0.2

def BODY_H() -> F32:
  0.6

# ===== Palette =====

def RGB(r: U32, g: U32, b: U32) -> U32:
  U32.or(U32.or(U32.shln(r, 16n), U32.shln(g, 8n)), b)

def PANEL() -> U32:
  RGB(214, 214, 208)

def SEAM() -> U32:
  RGB(140, 142, 140)

def METAL() -> U32:
  RGB(74, 70, 66)

def METAL_SEAM() -> U32:
  RGB(40, 38, 36)

def BLUE() -> U32:
  RGB(40, 150, 255)

def ORANGE() -> U32:
  RGB(255, 145, 25)

def EXIT() -> U32:
  RGB(70, 230, 120)

def VOID() -> U32:
  RGB(12, 12, 16)

def CEIL() -> U32:
  RGB(62, 64, 72)

def CEIL_WON() -> U32:
  RGB(50, 150, 90)

def FLOOR() -> U32:
  RGB(96, 98, 104)

def HAIR() -> U32:
  RGB(60, 40, 30)

def SKIN() -> U32:
  RGB(232, 190, 160)

def SHIRT() -> U32:
  RGB(228, 228, 222)

def SUIT() -> U32:
  RGB(238, 120, 36)

def BOOT() -> U32:
  RGB(245, 245, 245)
