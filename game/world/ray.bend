import Base
import ../core/config.bend as C
import ../core/types.bend as T
import ../core/num.bend as Num
import ./level.bend as Level
import ./face.bend as Face
import ./portals.bend as Portal

# DDA raycasting. A ray that hits an open portal continues from the other portal.

def finish(+mx: U32, +my: U32, +side: U32, +t: F32, glass: Bool, +negx: Bool, +negy: Bool, +ox: F32, +oy: F32, +dx: F32, +dy: F32, +blue: T.Portal, +orange: T.Portal) -> T.Hit:
  +xs = U32.is_eq(side, 0)
  +face = Bool.pick(U32, xs, Bool.pick(U32, negx, 1, 0), Bool.pick(U32, negy, 3, 2))
  u = Num.frac(Bool.pick(F32, xs, (oy + dy * t : F32), (ox + dx * t : F32)))
  +is_b = Portal.at(blue, mx, my, face)
  +is_o = Portal.at(orange, mx, my, face)
  which = Bool.pick(U32, is_b, 1, Bool.pick(U32, is_o, 2, 0))
  through = Bool.or(Bool.and(is_b, Portal.is_on(orange)), Bool.and(is_o, Portal.is_on(blue)))
  T.Hit{t, mx, my, face, Level.cell(mx, my), u, glass, through, which, ox, oy, dx, dy}

# The next step gets "done" already calculated: the top match stops the loop and does not evaluate more steps.
def dda(fuel: Nat, done: Bool, +mx: U32, +my: U32, +sx: F32, +sy: F32, +ddx: F32, +ddy: F32, +negx: Bool, +negy: Bool, side: U32, t: F32, +glass: Bool, +ox: F32, +oy: F32, +dx: F32, +dy: F32, +blue: T.Portal, +orange: T.Portal) -> T.Hit:
  match fuel done:
    case 0n _:
      finish(mx, my, side, t, glass, negx, negy, ox, oy, dx, dy, blue, orange)
    case 1n+f True{}:
      finish(mx, my, side, t, glass, negx, negy, ox, oy, dx, dy, blue, orange)
    case 1n+f False{}:
      +xs = F32.is_lt(sx, sy)
      +nmx = Bool.pick(U32, xs, Bool.pick(U32, negx, (mx - 1 : U32), (mx + 1 : U32)), mx)
      +nmy = Bool.pick(U32, xs, my, Bool.pick(U32, negy, (my - 1 : U32), (my + 1 : U32)))
      +code = Level.cell(nmx, nmy)
      nsx = Bool.pick(F32, xs, (sx + ddx : F32), sx)
      nsy = Bool.pick(F32, xs, sy, (sy + ddy : F32))
      dda(f, Level.stops_ray(code), nmx, nmy, nsx, nsy, ddx, ddy, negx, negy, Bool.pick(U32, xs, 0, 1), Bool.pick(F32, xs, sx, sy), Bool.or(glass, U32.is_eq(code, 2)), ox, oy, dx, dy, blue, orange)

def start(+ox: F32, +oy: F32, +dx: F32, +dy: F32, +blue: T.Portal, +orange: T.Portal) -> T.Hit:
  +mx = F32.to_u32(F32.floor(ox))
  +my = F32.to_u32(F32.floor(oy))
  +ddx = (1.0 / F32.max(F32.abs(dx), 0.0001) : F32)
  +ddy = (1.0 / F32.max(F32.abs(dy), 0.0001) : F32)
  +negx = F32.is_lt(dx, 0.0)
  +negy = F32.is_lt(dy, 0.0)
  sx = Bool.pick(F32, negx, ((ox - U32.to_f32(mx)) * ddx : F32), ((U32.to_f32(mx) + 1.0 - ox) * ddx : F32))
  sy = Bool.pick(F32, negy, ((oy - U32.to_f32(my)) * ddy : F32), ((U32.to_f32(my) + 1.0 - oy) * ddy : F32))
  dda(C.FUEL(), False{}, mx, my, sx, sy, ddx, ddy, negx, negy, 0, 0.0, False{}, ox, oy, dx, dy, blue, orange)

# A ray that goes into src at (x, y) comes out of dst: the point and the direction turn by the angle between the faces.
def emerge(src: T.Portal, dst: T.Portal, x: F32, y: F32, +dx: F32, +dy: F32, +blue: T.Portal, +orange: T.Portal) -> T.Hit:
  match src dst:
    case T.Portal{son, +scx, +scy, +sf} T.Portal{don, +dcx, +dcy, +df}:
      +phi = (Face.angle(df) + F32.pi() - Face.angle(sf) : F32)
      +c = F32.cos(phi)
      +s = F32.sin(phi)
      +rx = (x - Face.mx(sf, scx) : F32)
      +ry = (y - Face.my(sf, scy) : F32)
      wx = (Face.mx(df, dcx) + c * rx - s * ry + Face.nx(df) * 0.001 : F32)
      wy = (Face.my(df, dcy) + s * rx + c * ry + Face.ny(df) * 0.001 : F32)
      start(wx, wy, (c * dx - s * dy : F32), (s * dx + c * dy : F32), blue, orange)

# Signed distance from the ray point at tt to the clip plane (point s, normal sn). Positive = in front.
def side(+ox: F32, +oy: F32, +dx: F32, +dy: F32, +tt: F32, sx: F32, sy: F32, snx: F32, sny: F32) -> F32:
  (((ox + dx * tt) - sx) * snx + ((oy + dy * tt) - sy) * sny : F32)

# Where the ray segment goes through the player body at (px, py): the distance on the segment, or 0 if it misses.
# The body is a cylinder with radius BODY_HALF. The ray crosses the cylinder on a chord (near..far),
# and the body shows if a part of the chord is before the wall and in front of the clip plane.
# The chord must start after the segment origin: a viewpoint inside the body does not see the body.
# This occurs on the segment that leaves one portal while the player crosses the other portal.
def body_t(+ox: F32, +oy: F32, +dx: F32, +dy: F32, t: F32, +px: F32, +py: F32, +sx: F32, +sy: F32, +snx: F32, +sny: F32) -> F32:
  +len = F32.hypot(dx, dy)
  +along = (((px - ox) * dx + (py - oy) * dy) / (len * len) : F32)
  +aside = (((px - ox) * dy - (py - oy) * dx) / len : F32)
  +half = (F32.sqrt(F32.max((C.BODY_HALF() * C.BODY_HALF() - aside * aside : F32), 0.0)) / len : F32)
  +near = (along - half : F32)
  +far = (along + half : F32)
  ahead = Bool.and(F32.is_gt(near, 0.0), F32.is_lt(near, t))
  kept = Bool.or(F32.is_ge(side(ox, oy, dx, dy, near, sx, sy, snx, sny), 0.0), F32.is_ge(side(ox, oy, dx, dy, far, sx, sy, snx, sny), 0.0))
  Bool.pick(F32, Bool.and(Bool.and(ahead, kept), F32.is_lt(F32.abs(aside), C.BODY_HALF())), along, 0.0)

def body_u(+ox: F32, +oy: F32, +dx: F32, +dy: F32, +px: F32, +py: F32) -> F32:
  (((px - ox) * dy - (py - oy) * dx) / F32.hypot(dx, dy) / C.BODY_HALF() : F32)
