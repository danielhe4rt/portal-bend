import Base
import ../core/config.bend as C
import ../core/types.bend as T
import ./face.bend as Face

def off() -> T.Portal:
  T.Portal{False{}, 0, 0, 0}

def is_on(p: T.Portal) -> Bool:
  match p:
    case T.Portal{on, cx, cy, face}:
      on

def at(p: T.Portal, +x: U32, +y: U32, +f: U32) -> Bool:
  match p:
    case T.Portal{on, cx, cy, face}:
      Bool.and(on, Bool.and(U32.is_eq(cx, x), Bool.and(U32.is_eq(cy, y), U32.is_eq(face, f))))

# The portal mouth: (cx, cy) is the portal cell, and the center (x, y) is in the gap of the face,
# in front of it or just inside. On the other sides, the cell is still a wall.
# The gap is the drawn ellipse minus the body radius: the full body must fit in the portal.
def mouth(p: T.Portal, +cx: U32, +cy: U32, x: F32, y: F32) -> Bool:
  match p:
    case T.Portal{on, +pcx, +pcy, +face}:
      +rx = (x - Face.mx(face, pcx) : F32)
      +ry = (y - Face.my(face, pcy) : F32)
      +nx = Face.nx(face)
      +ny = Face.ny(face)
      depth = (rx * nx + ry * ny : F32)
      lateral = (F32.abs((rx * ny : F32)) + F32.abs((ry * nx : F32)) : F32)
      same_cell = Bool.and(U32.is_eq(cx, pcx), U32.is_eq(cy, pcy))
      in_gap = Bool.and(F32.is_gt(depth, F32.neg(0.5)), F32.is_lt(lateral, (C.PORTAL_RX() - C.RADIUS() : F32)))
      Bool.and(on, Bool.and(same_cell, in_gap))
