import Base
import ../core/config.bend as C

# Vertical projection. hor = horizon row in pixels; eye = eye height between the floor (0) and the ceiling (1).
# sc = height in pixels of a wall at distance 1.
# A point at height h and distance dist goes to y = hor + (eye - h) * sc / dist.

def at(h: F32, dist: F32, hor: F32, eye: F32, sc: F32) -> F32:
  (hor + (eye - h) * sc / F32.max(dist, 0.05) : F32)

def top(dist: F32, hor: F32, eye: F32, sc: F32) -> F32:
  at(1.0, dist, hor, eye, sc)

def bot(dist: F32, hor: F32, eye: F32, sc: F32) -> F32:
  at(0.0, dist, hor, eye, sc)
