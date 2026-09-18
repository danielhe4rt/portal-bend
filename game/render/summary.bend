import Base
import ../core/types.bend as T
import ./col.bend as Col

# The summary (T.Sum) of a range of columns, and the questions that View asks it:
# does this screen block have one color only? Which color?

def of_col(+col: T.Seen) -> T.Sum:
  +clear = Bool.not(Col.front_figure(col))
  +lo = Bool.pick(F32, clear, Col.lo(col), F32.neg(1000000.0))
  +hi = Bool.pick(F32, clear, Col.hi(col), 1000000.0)
  T.Sum{lo, hi, lo, hi, Col.front_color(col), Bool.and(clear, Col.front_plain(col)), Col.hull(col, F32.neg(1.0)), Col.hull(col, 1.0), Col.hull(col, F32.neg(1.0)), Col.arc(col, F32.neg(1.0)), Col.arc(col, 1.0), Col.hull(col, 1.0), Col.ring_color(col), clear, Bool.pick(F32, clear, Col.core(col, F32.neg(1.0)), 1000000.0), Bool.pick(F32, clear, Col.core(col, 1.0), F32.neg(1000000.0)), Col.second_top(col), Col.second_bot(col), Col.window(col, F32.neg(1.0)), Col.window(col, 1.0), Col.wall_top(col), Col.wall_bot(col), Col.wall_top(col), Col.wall_bot(col), Col.wall_color(col), Col.back_plain(col)}

# A union uses min at the top and max at the bottom. An intersection does the opposite.
def join(a: T.Sum, b: T.Sum) -> T.Sum:
  match a b:
    case T.Sum{lo1, hi1, ftmax1, fbmin1, +fc1, fplain1, etop1, ebot1, rtop1, rarc_top1, rarc_bot1, rbot1, +pc1, pplain1, gtop1, gbot1, mlo1, mhi1, wtop1, wbot1, blo1, bhi1, btmax1, bbmin1, +bc1, bplain1} T.Sum{lo2, hi2, ftmax2, fbmin2, fc2, fplain2, etop2, ebot2, rtop2, rarc_top2, rarc_bot2, rbot2, pc2, pplain2, gtop2, gbot2, mlo2, mhi2, wtop2, wbot2, blo2, bhi2, btmax2, bbmin2, bc2, bplain2}:
      front_smooth = Bool.and(Bool.and(fplain1, fplain2), U32.is_eq(fc1, fc2))
      ring_smooth = Bool.and(Bool.and(pplain1, pplain2), U32.is_eq(pc1, pc2))
      back_smooth = Bool.and(Bool.and(bplain1, bplain2), U32.is_eq(bc1, bc2))
      T.Sum{F32.min(lo1, lo2), F32.max(hi1, hi2), F32.max(ftmax1, ftmax2), F32.min(fbmin1, fbmin2), fc1, front_smooth, F32.min(etop1, etop2), F32.max(ebot1, ebot2), F32.max(rtop1, rtop2), F32.min(rarc_top1, rarc_top2), F32.max(rarc_bot1, rarc_bot2), F32.min(rbot1, rbot2), pc1, ring_smooth, F32.max(gtop1, gtop2), F32.min(gbot1, gbot2), F32.min(mlo1, mlo2), F32.max(mhi1, mhi2), F32.max(wtop1, wtop2), F32.min(wbot1, wbot2), F32.min(blo1, blo2), F32.max(bhi1, bhi2), F32.max(btmax1, btmax2), F32.min(bbmin1, bbmin2), bc1, back_smooth}

# The sampled rows of the block (first to last) are in [from, to].
def fits(+y0: U32, +s: U32, from: F32, to: F32) -> Bool:
  ya = (U32.to_f32(y0) + 1.0 : F32)
  yb = (U32.to_f32((y0 + s : U32)) - 1.0 : F32)
  Bool.and(F32.is_ge(ya, from), F32.is_le(yb, to))

# The rows of the block are in the wall in all columns, and not on a horizontal seam (top, middle and bottom).
def between_seams(+y0: U32, +s: U32, +tmin: F32, +bmax: F32, +tmax: F32, +bmin: F32) -> Bool:
  +d = (F32.max(((bmax - tmin) * 0.0125 : F32), 0.75) + 1.0 : F32)
  +ya = (U32.to_f32(y0) + 1.0 : F32)
  +yb = (U32.to_f32((y0 + s : U32)) - 1.0 : F32)
  inside = Bool.and(F32.is_ge(ya, (tmax + d : F32)), F32.is_le(yb, (bmin - d : F32)))
  clear = Bool.or(F32.is_le(yb, ((tmin + bmin) / 2.0 - d : F32)), F32.is_ge(ya, ((tmax + bmax) / 2.0 + d : F32)))
  Bool.and(inside, clear)

# What covers the full block with one color:
# 0 = nothing, 1 = front wall, 2 = back wall through the portal window, 3 = front portal ring.
def solid_kind(+y0: U32, +s: U32, sm: T.Sum) -> U32:
  match sm:
    case T.Sum{lo, hi, ftmax, fbmin, fc, fplain, etop, ebot, rtop, rarc_top, rarc_bot, rbot, pc, pplain, gtop, gbot, mlo, mhi, wtop, wbot, blo, bhi, btmax, bbmin, bc, bplain}:
      off_ellipse = Bool.or(fits(y0, s, F32.neg(1000000.0), etop), fits(y0, s, ebot, 1000000.0))
      front = Bool.and(Bool.and(fplain, off_ellipse), between_seams(y0, s, lo, hi, ftmax, fbmin))
      back = Bool.and(Bool.and(bplain, fits(y0, s, wtop, wbot)), between_seams(y0, s, blo, bhi, btmax, bbmin))
      ring = Bool.and(pplain, Bool.or(fits(y0, s, rtop, rarc_top), fits(y0, s, rarc_bot, rbot)))
      Bool.pick(U32, front, 1, Bool.pick(U32, back, 2, Bool.pick(U32, ring, 3, 0)))

def solid_paint(+kind: U32, sm: T.Sum) -> U32:
  match sm:
    case T.Sum{lo, hi, ftmax, fbmin, fc, fplain, etop, ebot, rtop, rarc_top, rarc_bot, rbot, pc, pplain, gtop, gbot, mlo, mhi, wtop, wbot, blo, bhi, btmax, bbmin, bc, bplain}:
      Bool.pick(U32, U32.is_eq(kind, 1), fc, Bool.pick(U32, U32.is_eq(kind, 2), bc, pc))

# The block shows only ceiling or only floor: above or below all of the front,
# or, through the front portal core, above or below the second node.
def only_flat(+y0: U32, +s: U32, sm: T.Sum) -> Bool:
  match sm:
    case T.Sum{lo, hi, ftmax, fbmin, fc, fplain, etop, ebot, rtop, rarc_top, rarc_bot, rbot, pc, pplain, gtop, gbot, mlo, mhi, wtop, wbot, blo, bhi, btmax, bbmin, bc, bplain}:
      +block_top = U32.to_f32(y0)
      +block_bot = U32.to_f32((y0 + s : U32))
      front = Bool.or(F32.is_le(block_bot, lo), F32.is_ge(block_top, hi))
      through = Bool.and(fits(y0, s, gtop, gbot), Bool.or(F32.is_le(block_bot, mlo), F32.is_ge(block_top, mhi)))
      Bool.or(front, through)
