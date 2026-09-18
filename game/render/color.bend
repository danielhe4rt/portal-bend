import Base
import ../core/config.bend as C

# Colors 0xRRGGBB, fog, and the floor and ceiling gradient.

def scale(+base: U32, +f: F32) -> U32:
  r = (U32.to_f32(U32.and(U32.shrn(base, 16n), 255)) * f : F32)
  g = (U32.to_f32(U32.and(U32.shrn(base, 8n), 255)) * f : F32)
  b = (U32.to_f32(U32.and(base, 255)) * f : F32)
  C.RGB(F32.to_u32(r), F32.to_u32(g), F32.to_u32(b))

def dim(c: U32) -> U32:
  U32.and(U32.shr(c), 8355711)

def mix(a: U32, b: U32) -> U32:
  (dim(a) + dim(b) : U32)

# Fog has 40 levels: adjacent columns repeat the color, so the wall compresses into blocks.
def fog(dist: F32) -> F32:
  (F32.floor((F32.clamp((1.0 - dist / 18.0 : F32), 0.2, 1.0) * 40.0 : F32)) / 40.0 : F32)

def shade(+base: U32, dist: F32, +face: U32, +glass: Bool) -> U32:
  +f = (fog(dist) * Bool.pick(F32, U32.is_lt(face, 2), 1.0, 0.8) : F32)
  r = (U32.to_f32(U32.and(U32.shrn(base, 16n), 255)) * f : F32)
  g = (U32.to_f32(U32.and(U32.shrn(base, 8n), 255)) * f : F32)
  b = (U32.to_f32(U32.and(base, 255)) * f : F32)
  +k = Bool.pick(F32, glass, 0.7, 1.0)
  +m = Bool.pick(F32, glass, 1.0, 0.0)
  C.RGB(F32.to_u32((r * k + 30.0 * m : F32)), F32.to_u32((g * k + 55.0 * m : F32)), F32.to_u32((b * k + 70.0 * m : F32)))

# Floor and ceiling get darker with distance in 12 bands: a block in one band becomes one Pix.
def flat_level(+yc: F32, +hor: F32, +eye: F32, sc: F32) -> U32:
  +above = F32.is_lt(yc, hor)
  span = F32.max(Bool.pick(F32, above, (hor - yc : F32), (yc - hor : F32)), 0.5)
  height = Bool.pick(F32, above, (1.0 - eye : F32), eye)
  dist = (height * sc / span : F32)
  F32.to_u32((F32.clamp((1.0 - dist / 18.0 : F32), 0.2, 1.0) * 12.0 : F32))

def flat(+yc: F32, +hor: F32, eye: F32, sc: F32, cb: U32) -> U32:
  base = Bool.pick(U32, F32.is_lt(yc, hor), cb, C.FLOOR())
  scale(base, (U32.to_f32(flat_level(yc, hor, eye, sc)) / 12.0 : F32))
