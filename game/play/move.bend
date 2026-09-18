import Base
import ../core/config.bend as C
import ../core/types.bend as T
import ../world/level.bend as Level
import ../world/face.bend as Face
import ../world/portals.bend as Portal

# Collision on each axis, and portal crossing.
# As in the original Portal: the wall opens a hole only at the portal mouth,
# and the teleport occurs when the body center crosses the face plane, with no push.

def blocks(+cx: U32, +cy: U32, +x: F32, +y: F32, open: Bool, blue: T.Portal, orange: T.Portal) -> Bool:
  solid = Bool.not(U32.is_eq(Level.cell(cx, cy), 0))
  hole = Bool.and(open, Bool.or(Portal.mouth(blue, cx, cy, x, y), Portal.mouth(orange, cx, cy, x, y)))
  Bool.and(solid, Bool.not(hole))

# (nx, y) = candidate center. Test the two corners on the side where the body moves.
def hits_x(+nx: F32, +y: F32, vx: F32, +open: Bool, +blue: T.Portal, +orange: T.Portal) -> Bool:
  reach = Bool.pick(F32, F32.is_gt(vx, 0.0), C.RADIUS(), F32.neg(C.RADIUS()))
  +edge = F32.to_u32(F32.floor((nx + reach : F32)))
  lo = blocks(edge, F32.to_u32(F32.floor((y - C.RADIUS() : F32))), nx, y, open, blue, orange)
  hi = blocks(edge, F32.to_u32(F32.floor((y + C.RADIUS() : F32))), nx, y, open, blue, orange)
  Bool.or(lo, hi)

def hits_y(+x: F32, +ny: F32, vy: F32, +open: Bool, +blue: T.Portal, +orange: T.Portal) -> Bool:
  reach = Bool.pick(F32, F32.is_gt(vy, 0.0), C.RADIUS(), F32.neg(C.RADIUS()))
  +edge = F32.to_u32(F32.floor((ny + reach : F32)))
  lo = blocks(F32.to_u32(F32.floor((x - C.RADIUS() : F32))), edge, x, ny, open, blue, orange)
  hi = blocks(F32.to_u32(F32.floor((x + C.RADIUS() : F32))), edge, x, ny, open, blue, orange)
  Bool.or(lo, hi)

# The depth of the center in src becomes the distance in front of dst.
def warp(src: T.Portal, dst: T.Portal, x: F32, y: F32, hitx: Bool, hity: Bool) -> T.Step:
  match src dst:
    case T.Portal{son, +scx, +scy, +sf} T.Portal{don, +dcx, +dcy, +df}:
      +phi = (Face.angle(df) + F32.pi() - Face.angle(sf) : F32)
      +c = F32.cos(phi)
      +s = F32.sin(phi)
      +rx = (x - Face.mx(sf, scx) : F32)
      +ry = (y - Face.my(sf, scy) : F32)
      wx = (Face.mx(df, dcx) + c * rx - s * ry + Face.nx(df) * 0.001 : F32)
      wy = (Face.my(df, dcy) + s * rx + c * ry + Face.ny(df) * 0.001 : F32)
      T.Step{wx, wy, phi, hitx, hity, Face.nx(df), Face.ny(df)}

def leave(+x: F32, +y: F32, +hitx: Bool, +hity: Bool, +open: Bool, +blue: T.Portal, +orange: T.Portal) -> T.Step:
  +cx = F32.to_u32(F32.floor(x))
  +cy = F32.to_u32(F32.floor(y))
  in_blue = Bool.and(open, Portal.mouth(blue, cx, cy, x, y))
  in_orange = Bool.and(open, Portal.mouth(orange, cx, cy, x, y))
  Bool.pick(T.Step, in_blue, warp(blue, orange, x, y, hitx, hity), Bool.pick(T.Step, in_orange, warp(orange, blue, x, y, hitx, hity), T.Step{x, y, 0.0, hitx, hity, 0.0, 0.0}))

def both(+px: F32, +py: F32, +vx: F32, +vy: F32, +blue: T.Portal, +orange: T.Portal) -> T.Step:
  +open = Bool.and(Portal.is_on(blue), Portal.is_on(orange))
  +nx = (px + vx : F32)
  +hitx = hits_x(nx, py, vx, open, blue, orange)
  +x1 = Bool.pick(F32, hitx, px, nx)
  +ny = (py + vy : F32)
  +hity = hits_y(x1, ny, vy, open, blue, orange)
  y1 = Bool.pick(F32, hity, py, ny)
  leave(x1, y1, hitx, hity, open, blue, orange)

# Funneling: a body that moves to a portal mouth gets a small pull to its center.
# Returns the speed change on one axis.
def funnel(p: T.Portal, open: Bool, x: F32, y: F32, vx: F32, vy: F32, along_x: Bool) -> F32:
  match p:
    case T.Portal{on, +cx, +cy, +face}:
      +rx = (x - Face.mx(face, cx) : F32)
      +ry = (y - Face.my(face, cy) : F32)
      +nx = Face.nx(face)
      +ny = Face.ny(face)
      +depth = (rx * nx + ry * ny : F32)
      lateral = (F32.abs((rx * ny : F32)) + F32.abs((ry * nx : F32)) : F32)
      closing = F32.is_lt((vx * nx + vy * ny : F32), F32.neg(0.004))
      in_front = Bool.and(F32.is_gt(depth, 0.0), F32.is_lt(depth, C.FUNNEL_REACH()))
      pulled = Bool.and(open, Bool.and(closing, Bool.and(in_front, F32.is_lt(lateral, 0.5))))
      toward_center = Bool.pick(F32, along_x, (F32.neg(rx) * F32.abs(ny) : F32), (F32.neg(ry) * F32.abs(nx) : F32))
      Bool.pick(F32, pulled, (toward_center * C.FUNNEL() : F32), 0.0)
