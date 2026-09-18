import Base
import ../core/config.bend as C
import ../core/types.bend as T
import ../core/num.bend as Num
import ../world/ray.bend as Ray
import ./proj.bend as Proj
import ./color.bend as Color

# One screen column: cast the ray, follow it from portal to portal and project each wall on the path.
# The result is a chain Gate -> Gate -> ... -> Wall, from near to far.

def no_figure() -> T.Figure:
  T.Figure{False{}, 0.0, 0.0, 0.0, 0.0}

def no_bodies() -> T.Bodies:
  T.Bodies{no_figure(), no_figure()}

def shown(bs: T.Bodies) -> Bool:
  match bs:
    case T.Bodies{T.Figure{a, at, ab, au, af}, T.Figure{b, bt, bb, bu, bf}}:
      Bool.or(a, b)

def empty(+hor: F32) -> T.Seen:
  T.Wall{hor, hor, 0, 0, False{}, False{}, no_bodies()}

def base_color(+code: U32, +which: U32) -> U32:
  wall = Bool.pick(U32, U32.is_eq(code, 3), C.EXIT(), Bool.pick(U32, U32.is_eq(code, 1), C.PANEL(), Bool.pick(U32, U32.is_eq(code, 4), C.METAL(), C.VOID())))
  Bool.pick(U32, U32.is_eq(which, 1), C.BLUE(), Bool.pick(U32, U32.is_eq(which, 2), C.ORANGE(), wall))

# One body (the original or the clone) seen in the ray segment that starts at (ox, oy), after projection.
# acc = distance before the segment. feet = feet height: the body goes up with the jump.
def one(+ox: F32, +oy: F32, +dx: F32, +dy: F32, +t: F32, +on: Bool, +x: F32, +y: F32, sx: F32, sy: F32, snx: F32, sny: F32, +acc: F32, +hor: F32, +eye: F32, +sc: F32, +feet: F32) -> T.Figure:
  +found = Bool.pick(F32, on, Ray.body_t(ox, oy, dx, dy, t, x, y, sx, sy, snx, sny), 0.0)
  +dist = (acc + found : F32)
  T.Figure{F32.is_gt(found, 0.0), Proj.at((feet + C.BODY_H() : F32), dist, hor, eye, sc), Proj.at(feet, dist, hor, eye, sc), Ray.body_u(ox, oy, dx, dy, x, y), Color.fog(dist)}

# Farther = smaller sprite = base nearer to the horizon.
def order(a: T.Figure, b: T.Figure) -> T.Bodies:
  match a b:
    case T.Figure{+aon, +at, +ab, +au, +af} T.Figure{+bon, +bt, +bb, +bu, +bf}:
      a_first = Bool.or(Bool.not(bon), Bool.and(aon, F32.is_ge(ab, bb)))
      Bool.pick(T.Bodies, a_first, T.Bodies{T.Figure{aon, at, ab, au, af}, T.Figure{bon, bt, bb, bu, bf}}, T.Bodies{T.Figure{bon, bt, bb, bu, bf}, T.Figure{aon, at, ab, au, af}})

# The player in the ray segment: the original and the clone, each clipped by the plane of its portal.
# In the first segment the origin is the player, so the original does not show.
def figure(+ox: F32, +oy: F32, +dx: F32, +dy: F32, +t: F32, g: T.Ghost, +acc: F32, +hor: F32, +eye: F32, +sc: F32, +feet: F32) -> T.Bodies:
  match g:
    case T.Ghost{x, y, ax, ay, anx, any, clone, cx, cy, bx, by, bnx, bny}:
      own = one(ox, oy, dx, dy, t, True{}, x, y, ax, ay, anx, any, acc, hor, eye, sc, feet)
      copy = one(ox, oy, dx, dy, t, clone, cx, cy, bx, by, bnx, bny, acc, hor, eye, sc, feet)
      order(own, copy)

def wall_node(+dist: F32, +code: U32, u: F32, +glass: Bool, +which: U32, +face: U32, body: T.Bodies, +hor: F32, +eye: F32, +sc: F32) -> T.Seen:
  tiled = Bool.and(Bool.or(U32.is_eq(code, 1), U32.is_eq(code, 4)), U32.is_eq(which, 0))
  line = Bool.pick(U32, U32.is_eq(code, 4), C.METAL_SEAM(), C.SEAM())
  T.Wall{Proj.top(dist, hor, eye, sc), Proj.bot(dist, hor, eye, sc), Color.shade(base_color(code, which), dist, face, glass), Color.shade(line, dist, face, glass), Num.seam(u), tiled, body}

def gate_node(+dist: F32, +u: F32, +face: U32, +glass: Bool, which: U32, open: Bool, body: T.Bodies, next: T.Seen, +hor: F32, +eye: F32, +sc: F32) -> T.Seen:
  ring_color = Color.scale(Bool.pick(U32, U32.is_eq(which, 1), C.BLUE(), C.ORANGE()), Color.fog(dist))
  T.Gate{Proj.top(dist, hor, eye, sc), Proj.bot(dist, hor, eye, sc), u, Color.shade(C.PANEL(), dist, face, glass), Color.shade(C.SEAM(), dist, face, glass), Num.seam(u), ring_color, open, body, next}

# End of the path. A portal without a pair, or past the pass limit, becomes a closed Gate.
def close(+dist: F32, +code: U32, +u: F32, +glass: Bool, +which: U32, +face: U32, +body: T.Bodies, +hor: F32, +eye: F32, +sc: F32) -> T.Seen:
  +wall = wall_node(dist, code, u, glass, which, face, body, hor, eye, sc)
  Bool.pick(T.Seen, U32.is_eq(which, 0), wall, gate_node(dist, u, face, glass, which, False{}, body, wall, hor, eye, sc))

def trace(pf: Nat, hit: T.Hit, +acc: F32, +glass: Bool, +ghost: T.Ghost, +blue: T.Portal, +orange: T.Portal, +hor: F32, +eye: F32, +sc: F32, +feet: F32) -> T.Seen:
  match pf hit:
    case 0n T.Hit{+t, cx, cy, face, code, u, g, thru, which, ox, oy, dx, dy}:
      close((acc + t : F32), code, u, Bool.or(glass, g), which, face, figure(ox, oy, dx, dy, t, ghost, acc, hor, eye, sc, feet), hor, eye, sc)
    case 1n+p T.Hit{+t, cx, cy, face, code, u, g, thru, +which, +ox, +oy, +dx, +dy}:
      match thru:
        case False{}:
          close((acc + t : F32), code, u, Bool.or(glass, g), which, face, figure(ox, oy, dx, dy, t, ghost, acc, hor, eye, sc, feet), hor, eye, sc)
        case True{}:
          +isb = U32.is_eq(which, 1)
          +dist = (acc + t : F32)
          +tinted = Bool.or(glass, g)
          next = Ray.emerge(Bool.pick(T.Portal, isb, blue, orange), Bool.pick(T.Portal, isb, orange, blue), (ox + dx * t : F32), (oy + dy * t : F32), dx, dy, blue, orange)
          gate_node(dist, u, face, tinted, which, True{}, figure(ox, oy, dx, dy, t, ghost, acc, hor, eye, sc, feet), trace(p, next, dist, tinted, ghost, blue, orange, hor, eye, sc, feet), hor, eye, sc)

def at(inside: Bool, +xc: U32, +w: U32, +px: F32, +py: F32, +dirx: F32, +diry: F32, +plx: F32, +ply: F32, +ghost: T.Ghost, +blue: T.Portal, +orange: T.Portal, +hor: F32, eye: F32, sc: F32, feet: F32) -> T.Seen:
  match inside:
    case False{}:
      empty(hor)
    case True{}:
      +cam = (2.0 * U32.to_f32(xc) / U32.to_f32(w) - 1.0 : F32)
      trace(C.PASSES(), Ray.start(px, py, (dirx + plx * cam : F32), (diry + ply * cam : F32), blue, orange), 0.0, False{}, ghost, blue, orange, hor, eye, sc, feet)

# ===== Readers for Sum.of_col =====

# Top and bottom of the front: the first node of the chain.
def lo(c: T.Seen) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      top
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      top

def hi(c: T.Seen) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      bot
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      bot

def front_color(c: T.Seen) -> U32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      wc
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      gc

def front_plain(c: T.Seen) -> Bool:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      Bool.not(seam)
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      Bool.not(seam)

def ring_color(c: T.Seen) -> U32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      0
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      pc

# Top and bottom of the second node: above and below it, through the front portal, only ceiling and floor show.
def second_top(c: T.Seen) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      1000000.0
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      lo(next)

def second_bot(c: T.Seen) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      F32.neg(1000000.0)
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      hi(next)

# Top, bottom and color of the wall where the ray stops: the last node of the chain.
def wall_top(c: T.Seen) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      top
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      wall_top(next)

def wall_bot(c: T.Seen) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      bot
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      wall_bot(next)

def wall_color(c: T.Seen) -> U32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      wc
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      wall_color(next)

def back_plain(c: T.Seen) -> Bool:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      Bool.not(seam)
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      back_plain(next)

# The body (or the clone) shows at the first node: it covers the wall, the ring and the floor of the column.
def front_figure(c: T.Seen) -> Bool:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, bs}:
      shown(bs)
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, bs, next}:
      shown(bs)

def any_figure(c: T.Seen) -> Bool:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, bs}:
      shown(bs)
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, bs, next}:
      Bool.or(shown(bs), any_figure(next))

# The row where the portal ellipse crosses "level" in this column (e = level; the outer edge is e = 1).
# sign = -1 returns the top crossing, +1 the bottom one. If the column does not reach the level, returns "miss".
def ellipse_row(+top: F32, bot: F32, u: F32, +level: F32, +sign: F32, miss: F32) -> F32:
  +eu = ((u - 0.5) / C.PORTAL_RX() : F32)
  +room = (level - eu * eu : F32)
  reach = (F32.sqrt(F32.max(room, 0.0)) * C.PORTAL_RY() * sign : F32)
  Bool.pick(F32, F32.is_gt(room, 0.0), (top + (bot - top) * (0.5 + reach) : F32), miss)

# The rows that the front portal ellipse touches. sign = -1 returns the top, +1 the bottom. With no ellipse, the range is empty.
def hull(c: T.Seen, +sign: F32) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      (sign * F32.neg(1000000.0) : F32)
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      ellipse_row(top, bot, u, 1.0, sign, (sign * F32.neg(1000000.0) : F32))

# Where the solid ring (e >= 0.84, above the maximum wave) ends on the inside.
# In a column that crosses only the ring, the ring fills the full ellipse: returns the opposite edge.
def arc(c: T.Seen, +sign: F32) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      (sign * F32.neg(1000000.0) : F32)
    case T.Gate{+top, +bot, +u, gc, gl, seam, pc, open, body, next}:
      ellipse_row(top, bot, u, 0.84, sign, ellipse_row(top, bot, u, 1.0, F32.neg(sign), (sign * F32.neg(1000000.0) : F32)))

# The front portal core (e < 0.5): no ring and no halo. Empty if the portal is closed or if the body shows in the chain.
def core(c: T.Seen, +sign: F32) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      (sign * F32.neg(1000000.0) : F32)
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      Bool.pick(F32, Bool.and(open, Bool.not(any_figure(next))), ellipse_row(top, bot, u, 0.5, sign, (sign * F32.neg(1000000.0) : F32)), (sign * F32.neg(1000000.0) : F32))

# Clear window: the rows inside the core of all portals in the chain, where only the last wall shows.
def gate_window(c: T.Seen, +sign: F32) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, bs}:
      Bool.pick(F32, shown(bs), (sign * F32.neg(1000000.0) : F32), (sign * 1000000.0 : F32))
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, bs, next}:
      +own = ellipse_row(top, bot, u, 0.5, sign, (sign * F32.neg(1000000.0) : F32))
      +rest = gate_window(next, sign)
      tight = Bool.pick(F32, F32.is_lt(sign, 0.0), F32.max(own, rest), F32.min(own, rest))
      Bool.pick(F32, Bool.and(open, Bool.not(shown(bs))), tight, (sign * F32.neg(1000000.0) : F32))

def window(c: T.Seen, +sign: F32) -> F32:
  match c:
    case T.Wall{top, bot, wc, wl, seam, tiled, body}:
      (sign * F32.neg(1000000.0) : F32)
    case T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}:
      gate_window(T.Gate{top, bot, u, gc, gl, seam, pc, open, body, next}, sign)
