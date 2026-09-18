import Base
import ../core/config.bend as C
import ../core/types.bend as T
import ./face.bend as Face
import ./portals.bend as Portal

# The player clone during a crossing, as in the original Portal:
# while the body is in the mouth of a portal, a visual copy shows at the other portal,
# at the same relative position. The plane of its portal clips each copy.

# The body (a sprite with half width BODY_HALF) touches the portal plane and is in the gap.
def crossing(p: T.Portal, x: F32, y: F32) -> Bool:
  match p:
    case T.Portal{on, +cx, +cy, +face}:
      +rx = (x - Face.mx(face, cx) : F32)
      +ry = (y - Face.my(face, cy) : F32)
      +nx = Face.nx(face)
      +ny = Face.ny(face)
      +depth = (rx * nx + ry * ny : F32)
      lateral = (F32.abs((rx * ny : F32)) + F32.abs((ry * nx : F32)) : F32)
      near_plane = Bool.and(F32.is_gt(depth, F32.neg(C.BODY_HALF())), F32.is_lt(depth, C.BODY_HALF()))
      Bool.and(on, Bool.and(near_plane, F32.is_lt(lateral, 0.5)))

# Move the body from src to dst with the same rotation as the teleport (Move.warp).
def carry(src: T.Portal, dst: T.Portal, +x: F32, +y: F32) -> T.Ghost:
  match src dst:
    case T.Portal{son, +scx, +scy, +sf} T.Portal{don, +dcx, +dcy, +df}:
      +phi = (Face.angle(df) + F32.pi() - Face.angle(sf) : F32)
      +c = F32.cos(phi)
      +s = F32.sin(phi)
      +ax = Face.mx(sf, scx)
      +ay = Face.my(sf, scy)
      +bx = Face.mx(df, dcx)
      +by = Face.my(df, dcy)
      +rx = (x - ax : F32)
      +ry = (y - ay : F32)
      T.Ghost{x, y, ax, ay, Face.nx(sf), Face.ny(sf), True{}, (bx + c * rx - s * ry : F32), (by + s * rx + c * ry : F32), bx, by, Face.nx(df), Face.ny(df)}

def alone(+x: F32, +y: F32) -> T.Ghost:
  T.Ghost{x, y, x, y, 0.0, 0.0, False{}, x, y, x, y, 0.0, 0.0}

def of(+x: F32, +y: F32, +blue: T.Portal, +orange: T.Portal) -> T.Ghost:
  +open = Bool.and(Portal.is_on(blue), Portal.is_on(orange))
  in_blue = Bool.and(open, crossing(blue, x, y))
  in_orange = Bool.and(open, crossing(orange, x, y))
  Bool.pick(T.Ghost, in_blue, carry(blue, orange, x, y), Bool.pick(T.Ghost, in_orange, carry(orange, blue, x, y), alone(x, y)))
