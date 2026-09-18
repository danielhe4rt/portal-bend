import Base
import ../core/config.bend as C
import ../core/types.bend as T
import ../world/portals.bend as Portal
import ../world/ghost.bend as Ghost
import ./color.bend as Color
import ./cols.bend as Cols
import ./summary.bend as Sum
import ./shade.bend as Shade

# Build the frame Image (quadtree) from the column tree.

# Crosshair: two bars at the center (cx, cy). A bar is bright when the portal of its color exists.
def leaf(+x0: U32, +y0: U32, col: T.Seen, +hor: F32, eye: F32, sc: F32, cb: U32, bon: Bool, oon: Bool, phase: F32, +cx: U32, +cy: U32) -> U32:
  +yc = (U32.to_f32(y0) + 1.0 : F32)
  +mid = Bool.and(U32.is_ge(y0, (cy - 2 : U32)), U32.is_lt(y0, (cy + 2 : U32)))
  left = Bool.and(mid, Bool.and(U32.is_ge(x0, (cx - 18 : U32)), U32.is_lt(x0, (cx - 6 : U32))))
  right = Bool.and(mid, Bool.and(U32.is_ge(x0, (cx + 6 : U32)), U32.is_lt(x0, (cx + 18 : U32))))
  scene = Shade.at(yc, col, Color.flat(yc, hor, eye, sc, cb), phase)
  Bool.pick(U32, left, Bool.pick(U32, bon, C.BLUE(), Color.dim(C.BLUE())), Bool.pick(U32, right, Bool.pick(U32, oon, C.ORANGE(), Color.dim(C.ORANGE())), scene))

def over_crosshair(+x0: U32, +y0: U32, +s: U32, +cx: U32, +cy: U32) -> Bool:
  xs = Bool.and(U32.is_lt(x0, (cx + 18 : U32)), U32.is_gt((x0 + s : U32), (cx - 18 : U32)))
  ys = Bool.and(U32.is_lt(y0, (cy + 2 : U32)), U32.is_gt((y0 + s : U32), (cy - 2 : U32)))
  Bool.and(xs, ys)

def uniform(+x0: U32, +y0: U32, +s: U32, sm: T.Sum, +hor: F32, +eye: F32, +sc: F32, kind: U32, +w: U32, +h: U32) -> Bool:
  out = Bool.or(U32.is_ge(x0, w), U32.is_ge(y0, h))
  one_band = U32.is_eq(Color.flat_level((U32.to_f32(y0) + 1.0 : F32), hor, eye, sc), Color.flat_level((U32.to_f32((y0 + s : U32)) - 1.0 : F32), hor, eye, sc))
  flat = Bool.and(one_band, Sum.only_flat(y0, s, sm))
  Bool.or(out, Bool.and(Bool.not(over_crosshair(x0, y0, s, U32.shr(w), U32.shr(h))), Bool.or(U32.is_gt(kind, 0), flat)))

# The parent calculates "uni": a block with one color becomes one Pix.
# kind and paint tell if the uniform block is solid (wall or ring, and its color) or floor and ceiling.
def build(+depth: Nat, uni: Bool, kind: U32, paint: U32, +x0: U32, +y0: U32, +size: U32, cols: T.Cols, +hor: F32, +eye: F32, +sc: F32, +cb: U32, +bon: Bool, +oon: Bool, +phase: F32, +w: U32, +h: U32) -> Image:
  match depth uni cols:
    case _ True{} _:
      out = Bool.or(U32.is_ge(x0, w), U32.is_ge(y0, h))
      Pix{Bool.pick(U32, out, 0, Bool.pick(U32, U32.is_gt(kind, 0), paint, Color.flat((U32.to_f32(y0) + 1.0 : F32), hor, eye, sc, cb)))}
    case 0n False{} T.CLeaf{sm, col}:
      Pix{leaf(x0, y0, col, hor, eye, sc, cb, bon, oon, phase, U32.shr(w), U32.shr(h))}
    case 0n False{} T.CNode{sm, l, r}:
      Pix{0}
    case 1n+d False{} T.CLeaf{sm, col}:
      Pix{0}
    case 1n+d False{} T.CNode{sm, +l, +r}:
      +half = U32.shr(size)
      +x1 = (x0 + half : U32)
      +y1 = (y0 + half : U32)
      +sl = Cols.sum(l)
      +sr = Cols.sum(r)
      +ktl = Sum.solid_kind(y0, half, sl)
      +ktr = Sum.solid_kind(y0, half, sr)
      +kbl = Sum.solid_kind(y1, half, sl)
      +kbr = Sum.solid_kind(y1, half, sr)
      tl tr = build(d, uniform(x0, y0, half, sl, hor, eye, sc, ktl, w, h), ktl, Sum.solid_paint(ktl, sl), x0, y0, half, l, hor, eye, sc, cb, bon, oon, phase, w, h) build(d, uniform(x1, y0, half, sr, hor, eye, sc, ktr, w, h), ktr, Sum.solid_paint(ktr, sr), x1, y0, half, r, hor, eye, sc, cb, bon, oon, phase, w, h)
      bl br = build(d, uniform(x0, y1, half, sl, hor, eye, sc, kbl, w, h), kbl, Sum.solid_paint(kbl, sl), x0, y1, half, l, hor, eye, sc, cb, bon, oon, phase, w, h) build(d, uniform(x1, y1, half, sr, hor, eye, sc, kbr, w, h), kbr, Sum.solid_paint(kbr, sr), x1, y1, half, r, hor, eye, sc, cb, bon, oon, phase, w, h)
      Qua{tl, tr, bl, br}

# The quadtree root is the smallest power of 2 that covers the window, as in Window.frame.
def root(fuel: Nat, +size: U32, +most: U32) -> U32:
  match fuel:
    case 0n:
      size
    case 1n+f:
      Bool.pick(U32, U32.is_ge(size, most), size, root(f, U32.shl(size), most))

def log2(fuel: Nat, +size: U32) -> U32:
  match fuel:
    case 0n:
      0
    case 1n+f:
      Bool.pick(U32, U32.is_gt(size, 1), (1 + log2(f, U32.shr(size)) : U32), 0)

# The tree goes from the root down to blocks of 2x2 pixels.
# sc increases with the window height and plane with the width: a wider window shows more to the sides.
def frame(+px: F32, +py: F32, +ang: F32, +hor: F32, +eye: F32, feet: F32, phase: F32, +blue: T.Portal, +orange: T.Portal, won: Bool, +w: U32, +h: U32) -> Image:
  +dirx = F32.cos(ang)
  +diry = F32.sin(ang)
  +size = root(32n, 2, U32.max(w, h))
  +depth = U32.to_nat((log2(32n, size) - 1 : U32))
  +sc = (U32.to_f32(h) * C.SCALE() / C.REF_H() : F32)
  +plane = (U32.to_f32(w) / (2.0 * sc) : F32)
  cols = Cols.build(depth, 0, size, px, py, dirx, diry, (F32.neg(diry) * plane : F32), (dirx * plane : F32), Ghost.of(px, py, blue, orange), blue, orange, hor, eye, sc, feet, w)
  cb = Bool.pick(U32, won, C.CEIL_WON(), C.CEIL())
  build(depth, False{}, 0, 0, 0, 0, size, cols, hor, eye, sc, cb, Portal.is_on(blue), Portal.is_on(orange), phase, w, h)

# Eye = 0.5 + jump height + step bob (only on the floor).
# Pitch uses the reference screen and increases with the window height.
def of(body: T.Body, look: T.Look, +blue: T.Portal, +orange: T.Portal, won: Bool, clock: F32, screen: T.Screen) -> Image:
  match body look screen:
    case T.Body{x, y, +z, vx, vy, vz} T.Look{ang, pitch, bob} T.Screen{+w, +h}:
      pace = F32.min((F32.hypot(vx, vy) / 0.06 : F32), 1.0)
      sway = Bool.pick(F32, F32.is_le(z, 0.0), (F32.sin(bob) * 0.02 * pace : F32), 0.0)
      eye = F32.clamp((0.5 + z + sway : F32), 0.1, 0.92)
      +fh = U32.to_f32(h)
      hor = (fh * 0.5 + pitch * fh / C.REF_H() : F32)
      frame(x, y, ang, hor, eye, z, clock, blue, orange, won, w, h)
