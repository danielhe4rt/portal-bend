import Base

# Geometry of a cell face. f: 0 = west, 1 = east, 2 = north, 3 = south.
# (nx, ny) = normal out of the wall; (mx, my) = center of the face.

def nx(+f: U32) -> F32:
  Bool.pick(F32, U32.is_eq(f, 0), F32.neg(1.0), Bool.pick(F32, U32.is_eq(f, 1), 1.0, 0.0))

def ny(+f: U32) -> F32:
  Bool.pick(F32, U32.is_eq(f, 2), F32.neg(1.0), Bool.pick(F32, U32.is_eq(f, 3), 1.0, 0.0))

def angle(+f: U32) -> F32:
  +half_pi = (F32.pi() / 2.0 : F32)
  Bool.pick(F32, U32.is_eq(f, 0), F32.pi(), Bool.pick(F32, U32.is_eq(f, 1), 0.0, Bool.pick(F32, U32.is_eq(f, 2), F32.neg(half_pi), half_pi)))

def mx(+f: U32, cx: U32) -> F32:
  (U32.to_f32(cx) + Bool.pick(F32, U32.is_eq(f, 0), 0.0, Bool.pick(F32, U32.is_eq(f, 1), 1.0, 0.5)) : F32)

def my(+f: U32, cy: U32) -> F32:
  (U32.to_f32(cy) + Bool.pick(F32, U32.is_eq(f, 2), 0.0, Bool.pick(F32, U32.is_eq(f, 3), 1.0, 0.5)) : F32)
