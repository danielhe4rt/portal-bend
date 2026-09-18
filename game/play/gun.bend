import Base
import ../core/config.bend as C
import ../core/types.bend as T
import ../world/portals.bend as Portal
import ../world/ray.bend as Ray
import ../render/proj.bend as Proj

# The portal gun: a shot also goes through open portals.

def follow(pf: Nat, hit: T.Hit, acc: F32, +blue: T.Portal, +orange: T.Portal) -> T.Hit:
  match pf hit:
    case 0n T.Hit{t, cx, cy, face, code, u, g, thru, which, ox, oy, dx, dy}:
      T.Hit{(acc + t : F32), cx, cy, face, code, u, g, thru, which, ox, oy, dx, dy}
    case 1n+p T.Hit{+t, cx, cy, face, code, u, g, thru, +which, +ox, +oy, +dx, +dy}:
      match thru:
        case False{}:
          T.Hit{(acc + t : F32), cx, cy, face, code, u, g, False{}, which, ox, oy, dx, dy}
        case True{}:
          +isb = U32.is_eq(which, 1)
          next = Ray.emerge(Bool.pick(T.Portal, isb, blue, orange), Bool.pick(T.Portal, isb, orange, blue), (ox + dx * t : F32), (oy + dy * t : F32), dx, dy, blue, orange)
          follow(p, next, (acc + t : F32), blue, orange)

# Only panels (code 1) accept a portal, never on top of the portal of the other color,
# and only when the aim is on the wall (not on the floor or the ceiling).
# This check uses the reference screen: the aim is at the center for all window sizes.
def to_portal(hit: T.Hit, keep: T.Portal, other: T.Portal, +hor: F32, +eye: F32) -> T.Portal:
  match hit:
    case T.Hit{+t, +cx, +cy, +face, code, u, g, thru, which, ox, oy, dx, dy}:
      aimed = Bool.and(F32.is_le(Proj.top(t, hor, eye, C.SCALE()), C.HALF_H()), F32.is_gt(Proj.bot(t, hor, eye, C.SCALE()), C.HALF_H()))
      free = Bool.and(U32.is_eq(code, 1), Bool.not(Portal.at(other, cx, cy, face)))
      Bool.pick(T.Portal, Bool.and(aimed, free), T.Portal{True{}, cx, cy, face}, keep)

def fire(+px: F32, +py: F32, +ang: F32, hor: F32, eye: F32, +blue: T.Portal, +orange: T.Portal, +is_blue: Bool) -> T.Portal:
  hit = follow(C.PASSES(), Ray.start(px, py, F32.cos(ang), F32.sin(ang), blue, orange), 0.0, blue, orange)
  to_portal(hit, Bool.pick(T.Portal, is_blue, blue, orange), Bool.pick(T.Portal, is_blue, orange, blue), hor, eye)
