import Base

# AFTER SHADERS.md: the same raycaster as one fork tree that ends in flat loops.
# The bang forks 4 ways from the 2048 root down to 16-px tiles (4^7 = 16384 lanes).
# A tile casts its 8 column pairs one time (a flat DDA loop), then writes its 16x16 pixels
# as straight-line Qua nodes (b16 = 4 b8 = 4 b4 = 4 blocks of 2x2). The map is 16 U32 row masks.
# The last frame goes down the tree as Four quadrants, and each tile drops its own quadrant.

def W() -> U32:
  1280

def H() -> U32:
  720

def pick(c: Bool, a: F32, b: F32) -> F32:
  match c:
    case True{}:
      a
    case False{}:
      b

def word(c: Bool, a: U32, b: U32) -> U32:
  match c:
    case True{}:
      a
    case False{}:
      b

type Cam is Data:
  Cam{px: F32, py: F32, dx: F32, dy: F32, plx: F32, ply: F32, hor: F32}

type Col is Data:
  Col{top: F32, bot: F32, c: U32}

type Four is Data:
  Four{a: Image, b: Image, c: Image, d: Image}

def stops(+y: U32) -> U32:
  word(U32.is_eq(y, 0), 65535, word(U32.is_eq(y, 1), 32897, word(U32.is_eq(y, 2), 32897, word(U32.is_eq(y, 3), 32769,
  word(U32.is_eq(y, 4), 32769, word(U32.is_eq(y, 5), 32897, word(U32.is_eq(y, 6), 33015, word(U32.is_eq(y, 7), 32769,
  word(U32.is_eq(y, 8), 32769, word(U32.is_eq(y, 9), 65409, word(U32.is_eq(y, 10), 32769, word(U32.is_eq(y, 11), 32769,
  word(U32.is_eq(y, 12), 32897, word(U32.is_eq(y, 13), 36993, word(U32.is_eq(y, 14), 32897, 65535)))))))))))))))

def metal(+y: U32) -> U32:
  word(U32.is_lt(y, 6), 0, word(U32.is_eq(y, 9), 0, word(U32.is_eq(y, 15), 32512, 32768)))

def bit(+row: U32, +x: U32) -> Bool:
  U32.is_ne(((row >> U32.to_nat(x)) .&. 1 : U32), 0)

type Ray is Data:
  Ray{t: F32, side: U32, mx: U32, my: U32}

def dda(fuel: Nat, more: Bool, +mx: U32, +my: U32, +sx: F32, +sy: F32, +ddx: F32, +ddy: F32, +negx: Bool, +negy: Bool, +side: U32, +t: F32) -> Ray:
  match fuel more:
    case _ False{}:
      Ray{t, side, mx, my}
    case 0n True{}:
      Ray{t, side, mx, my}
    case 1n+f True{}:
      +xs = (sx < sy : F32)
      +nmx = word(xs, word(negx, (mx - 1 : U32), (mx + 1 : U32)), mx)
      +nmy = word(xs, my, word(negy, (my - 1 : U32), (my + 1 : U32)))
      +hit = bit(stops(nmy), nmx)
      dda(f, Bool.not(hit), nmx, nmy, pick(xs, (sx + ddx : F32), sx), pick(xs, sy, (sy + ddy : F32)), ddx, ddy, negx, negy, word(xs, 0, 1), pick(xs, sx, sy))

def fog(+base: U32, +f: F32) -> U32:
  +r = (U32.to_f32(((base >> 16n) .&. 255 : U32)) * f : F32)
  +g = (U32.to_f32(((base >> 8n) .&. 255 : U32)) * f : F32)
  +b = (U32.to_f32((base .&. 255 : U32)) * f : F32)
  ((F32.to_u32(r) << 16n) .|. (F32.to_u32(g) << 8n) .|. F32.to_u32(b) : U32)

def paint(+r: Ray, +hor: F32) -> Col:
  Ray{t, side, mx, my} = r
  +d = F32.max(t, 0.05)
  +half = (400.0 / d : F32)
  +base = word(bit(metal(my), mx), 4867650, 14079696)
  +f = (F32.clamp((1.0 - d / 18.0 : F32), 0.2, 1.0) * pick(U32.is_eq(side, 0), 1.0, 0.8) : F32)
  Col{(hor - half : F32), (hor + half : F32), fog(base, f)}

def col(+x: U32, +cam: Cam) -> Col:
  Cam{px, py, dx, dy, plx, ply, hor} = cam
  +k = (2.0 * U32.to_f32((x + 1 : U32)) / U32.to_f32(W()) - 1.0 : F32)
  +rx = (dx + plx * k : F32)
  +ry = (dy + ply * k : F32)
  +mx = F32.to_u32(F32.floor(px))
  +my = F32.to_u32(F32.floor(py))
  +ddx = (1.0 / F32.max(F32.abs(rx), 0.0001) : F32)
  +ddy = (1.0 / F32.max(F32.abs(ry), 0.0001) : F32)
  +negx = (rx < 0.0 : F32)
  +negy = (ry < 0.0 : F32)
  +sx = pick(negx, ((px - U32.to_f32(mx)) * ddx : F32), ((U32.to_f32(mx) + 1.0 - px) * ddx : F32))
  +sy = pick(negy, ((py - U32.to_f32(my)) * ddy : F32), ((U32.to_f32(my) + 1.0 - py) * ddy : F32))
  paint(dda(40n, True{}, mx, my, sx, sy, ddx, ddy, negx, negy, 0, 0.0), hor)

def at(+c: Col, +y: U32) -> U32:
  Col{top, bot, k} = c
  +yc = (U32.to_f32(y) + 1.0 : F32)
  word((yc < top : F32), 4144200, word((yc < bot : F32), k, 6316648))

def one(same: Bool, +k0: U32, +k1: U32, +k2: U32, +k3: U32) -> Image:
  match same:
    case True{}:
      Pix{k0}
    case False{}:
      Qua{Pix{k0}, Pix{k1}, Pix{k2}, Pix{k3}}

def blk(+a: Col, +b: Col, +y: U32) -> Image:
  +k0 = at(a, y)
  +k1 = at(b, y)
  +k2 = at(a, (y + 1 : U32))
  +k3 = at(b, (y + 1 : U32))
  one((U32.is_eq(k0, k1) && U32.is_eq(k1, k2) && U32.is_eq(k2, k3)), k0, k1, k2, k3)

def b4(+c0: Col, +c1: Col, +y: U32) -> Image:
  Qua{blk(c0, c0, y), blk(c1, c1, y), blk(c0, c0, (y + 2 : U32)), blk(c1, c1, (y + 2 : U32))}

def b8(+c0: Col, +c1: Col, +c2: Col, +c3: Col, +y: U32) -> Image:
  Qua{b4(c0, c1, y), b4(c2, c3, y), b4(c0, c1, (y + 4 : U32)), b4(c2, c3, (y + 4 : U32))}

def b16(+c0: Col, +c1: Col, +c2: Col, +c3: Col, +c4: Col, +c5: Col, +c6: Col, +c7: Col, +y: U32) -> Image:
  Qua{b8(c0, c1, c2, c3, y), b8(c4, c5, c6, c7, y), b8(c0, c1, c2, c3, (y + 8 : U32)), b8(c4, c5, c6, c7, (y + 8 : U32))}

def tile(+x: U32, +y: U32, +cam: Cam, old: Four) -> Image:
  b16(col(x, cam), col((x + 2 : U32), cam), col((x + 4 : U32), cam), col((x + 6 : U32), cam),
    col((x + 8 : U32), cam), col((x + 10 : U32), cam), col((x + 12 : U32), cam), col((x + 14 : U32), cam), y)

def open(old: Image) -> Four:
  match old:
    case Pix{+c}:
      Four{Pix{c}, Pix{c}, Pix{c}, Pix{c}}
    case Qua{a, b, c, d}:
      Four{a, b, c, d}

def node(+k: Nat, on: Bool, +x: U32, +y: U32, +cam: Cam, old: Four) -> Image:
  match k on:
    case _ False{}:
      Pix{0}
    case 0n True{}:
      tile(x, y, cam, old)
    case 1n+e True{}:
      Four{oa, ob, oc, od} = old
      +s = U32.shln(16, e)
      +x1 = (x + s : U32)
      +y1 = (y + s : U32)
      a b c d = node(e, True{}, x, y, cam, open(oa)) node(e, (x1 < W() : U32), x1, y, cam, open(ob))
        node(e, (y1 < H() : U32), x, y1, cam, open(oc)) node(e, ((x1 < W()) && (y1 < H()) : U32), x1, y1, cam, open(od))
      Qua{a, b, c, d}

def show(+cam: Cam, old: Image) -> Image:
  node!(7n, True{}, 0, 0, cam, open(old))

def cam_at(+t: F32) -> Cam:
  +a = (t * 0.02 : F32)
  +dx = F32.cos(a)
  +dy = F32.sin(a)
  Cam{3.5, 3.5, dx, dy, (F32.neg(dy) * 0.8 : F32), (dx * 0.8 : F32), 360.0}
