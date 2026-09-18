import Base

# BEFORE SHADERS.md: a per-pixel raycaster in the shape of a GLSL shader.
# One fork per pixel (quad goes down to 1x1), and a second fold over the image (total) in the same bang.
# The map is arithmetic (border and pillars), so the pixel never reads scene data.

def solid(+x: U32, +y: U32) -> Bool:
  border = Bool.or(Bool.or(U32.is_eq(x, 0), U32.is_eq(y, 0)), Bool.or(U32.is_ge(x, 15), U32.is_ge(y, 15)))
  pillar = Bool.and(U32.is_eq(U32.and(x, 3), 2), U32.is_eq(U32.and(y, 3), 2))
  Bool.or(border, pillar)

def dda(fuel: Nat, done: Bool, +mx: U32, +my: U32, +sx: F32, +sy: F32, +ddx: F32, +ddy: F32, +negx: Bool, +negy: Bool, t: F32) -> F32:
  match fuel done:
    case 0n _:
      t
    case 1n+f True{}:
      t
    case 1n+f False{}:
      +xs = F32.is_lt(sx, sy)
      +nmx = Bool.pick(U32, xs, Bool.pick(U32, negx, (mx - 1 : U32), (mx + 1 : U32)), mx)
      +nmy = Bool.pick(U32, xs, my, Bool.pick(U32, negy, (my - 1 : U32), (my + 1 : U32)))
      nsx = Bool.pick(F32, xs, (sx + ddx : F32), sx)
      nsy = Bool.pick(F32, xs, sy, (sy + ddy : F32))
      dda(f, solid(nmx, nmy), nmx, nmy, nsx, nsy, ddx, ddy, negx, negy, Bool.pick(F32, xs, sx, sy))

def pix(+x: U32, +y: U32, +ang: F32) -> U32:
  +cam = (2.0 * U32.to_f32(x) / 1280.0 - 1.0 : F32)
  +dx = (F32.cos(ang) - F32.sin(ang) * 0.8 * cam : F32)
  +dy = (F32.sin(ang) + F32.cos(ang) * 0.8 * cam : F32)
  +ddx = (1.0 / F32.max(F32.abs(dx), 0.0001) : F32)
  +ddy = (1.0 / F32.max(F32.abs(dy), 0.0001) : F32)
  +negx = F32.is_lt(dx, 0.0)
  +negy = F32.is_lt(dy, 0.0)
  sx = Bool.pick(F32, negx, ((7.5 - 7.0) * ddx : F32), ((8.0 - 7.5) * ddx : F32))
  sy = Bool.pick(F32, negy, ((7.3 - 7.0) * ddy : F32), ((8.0 - 7.3) * ddy : F32))
  +t = dda(24n, False{}, 7, 7, sx, sy, ddx, ddy, negx, negy, 0.0)
  +half = (400.0 / F32.max(t, 0.05) : F32)
  +yc = U32.to_f32(y)
  wall = Bool.and(F32.is_ge(yc, (360.0 - half : F32)), F32.is_lt(yc, (360.0 + half : F32)))
  Bool.pick(U32, wall, F32.to_u32(F32.min((2000.0 / t : F32), 255.0)), Bool.pick(U32, F32.is_lt(yc, 360.0), 3355443, 6710886))

def quad(+depth: Nat, +x0: U32, +y0: U32, +size: U32, +ang: F32) -> Image:
  match depth:
    case 0n:
      Pix{pix(x0, y0, ang)}
    case 1n+d:
      +h = U32.shr(size)
      tl tr = quad(d, x0, y0, h, ang) quad(d, (x0 + h : U32), y0, h, ang)
      bl br = quad(d, x0, (y0 + h : U32), h, ang) quad(d, (x0 + h : U32), (y0 + h : U32), h, ang)
      Qua{tl, tr, bl, br}

def total(img: Image) -> U32:
  match img:
    case Pix{c}:
      U32.and(c, 255)
    case Qua{a, b, c, d}:
      x y = total(a) total(b)
      z w = total(c) total(d)
      (x + y + z + w : U32)

def frame_cpu(+ang: F32) -> U32:
  total(quad(11n, 0, 0, 2048, ang))

def frame_gpu(+ang: F32) -> U32:
  total(quad(11n, 0, 0, 2048, ang))

def loop_cpu(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      loop_cpu(p, (acc + frame_cpu((U32.to_f32(U32.from_nat(p)) * 0.1 : F32)) : U32))

def loop_gpu(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      loop_gpu(p, (acc + frame_gpu!((U32.to_f32(U32.from_nat(p)) * 0.1 : F32)) : U32))
