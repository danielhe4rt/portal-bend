import Base
import ../core/config.bend as C
import ../core/types.bend as T
import ../core/num.bend as Num
import ./color.bend as Color

# The color of one pixel in a column: wall, player body and portal.

def wall(+yc: F32, +top: F32, bot: F32, c: U32, l: U32, seam: Bool, tiled: Bool) -> U32:
  +h = F32.max((bot - top : F32), 0.001)
  +v = Num.frac(((yc - top) / h * 2.0 : F32))
  +th = F32.max(0.025, (1.5 / h : F32))
  vline = Bool.or(F32.is_lt(v, th), F32.is_gt(v, (1.0 - th : F32)))
  Bool.pick(U32, Bool.and(tiled, Bool.or(seam, vline)), l, c)

# flat = the floor or ceiling color for this row
def backdrop(+yc: F32, +top: F32, +bot: F32, c: U32, l: U32, seam: Bool, tiled: Bool, +flat: U32) -> U32:
  Bool.pick(U32, Bool.or(F32.is_lt(yc, top), F32.is_ge(yc, bot)), flat, wall(yc, top, bot, c, l, seam, tiled))

# The figure in body coordinates: a = 0 at the axis to 1 at the edge, v = 0 at the head to 1 at the feet.
def figure(+yc: F32, fig: T.Figure, behind: U32) -> U32:
  match fig:
    case T.Figure{shown, +top, +bot, su, fog}:
      +v = ((yc - top) / F32.max((bot - top : F32), 0.001) : F32)
      +a = F32.abs(su)
      +ha = (a / 0.45 : F32)
      +hv = ((v - 0.13) / 0.13 : F32)
      +head = F32.is_lt((ha * ha + hv * hv : F32), 1.0)
      +torso = Bool.and(F32.is_ge(v, 0.27), Bool.and(F32.is_lt(v, 0.62), F32.is_lt(a, 0.78)))
      legs = Bool.and(F32.is_ge(v, 0.62), Bool.and(F32.is_ge(a, 0.07), F32.is_lt(a, 0.6)))
      in_rows = Bool.and(F32.is_ge(yc, top), F32.is_lt(yc, bot))
      visible = Bool.and(shown, Bool.and(in_rows, Bool.or(head, Bool.or(torso, legs))))
      head_paint = Bool.pick(U32, F32.is_lt(v, 0.1), C.HAIR(), C.SKIN())
      torso_paint = Bool.pick(U32, F32.is_lt(v, 0.45), C.SHIRT(), C.SUIT())
      legs_paint = Bool.pick(U32, F32.is_gt(v, 0.93), C.BOOT(), C.SUIT())
      paint = Bool.pick(U32, head, head_paint, Bool.pick(U32, torso, torso_paint, legs_paint))
      Bool.pick(U32, visible, Color.scale(paint, fog), behind)

def bodies(+yc: F32, bs: T.Bodies, behind: U32) -> U32:
  match bs:
    case T.Bodies{near, far}:
      figure(yc, near, figure(yc, far, behind))

# Walk down the chain of one column. A portal is an ellipse on the wall. From the outside in: wall,
# ring in the portal color (it moves with phase), halo mixed with the other side, then the other side
# (or a dim color if the portal is closed).
# The caller calculates "wanted": outside the ellipse, the top match returns and does not go to the next node.
def seen(s: T.Seen, wanted: Bool, +yc: F32, +flat: U32, +phase: F32) -> U32:
  match s wanted:
    case _ False{}:
      0
    case T.Wall{top, bot, c, l, seam, tiled, fig} True{}:
      bodies(yc, fig, backdrop(yc, top, bot, c, l, seam, tiled, flat))
    case T.Gate{+top, +bot, +u, c, l, seam, +pc, +open, fig, next} True{}:
      +v = ((yc - top) / F32.max((bot - top : F32), 0.001) : F32)
      +eu = ((u - 0.5) / C.PORTAL_RX() : F32)
      +ev = ((v - 0.5) / C.PORTAL_RY() : F32)
      +e = (eu * eu + ev * ev : F32)
      +ring = (0.76 + F32.sin((eu * 7.0 + phase : F32)) * F32.cos((ev * 7.0 - phase * 2.0 : F32)) * 0.07 : F32)
      +in_slice = Bool.and(F32.is_ge(yc, top), F32.is_lt(yc, bot))
      looks_through = Bool.and(open, Bool.and(in_slice, F32.is_le(e, ring)))
      +other_side = Bool.pick(U32, open, seen(next, looks_through, yc, flat, phase), Color.dim(pc))
      halo = Bool.pick(U32, F32.is_gt(e, (ring - 0.16 : F32)), Color.mix(pc, other_side), other_side)
      inner = Bool.pick(U32, F32.is_gt(e, ring), pc, halo)
      surface = Bool.pick(U32, F32.is_lt(e, 1.0), inner, wall(yc, top, bot, c, l, seam, True{}))
      bodies(yc, fig, Bool.pick(U32, in_slice, surface, flat))

def at(yc: F32, col: T.Seen, flat: U32, phase: F32) -> U32:
  seen(col, True{}, yc, flat, phase)
