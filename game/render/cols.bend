import Base
import ../core/config.bend as C
import ../core/types.bend as T
import ./col.bend as Col
import ./summary.bend as Sum

# Binary tree of columns: each node has the summary (T.Sum) of the columns below it,
# and View uses the summary to replace full screen blocks with one Pix.

def sum(c: T.Cols) -> T.Sum:
  match c:
    case T.CLeaf{sm, col}:
      sm
    case T.CNode{sm, l, r}:
      sm

def leaf(+col: T.Seen) -> T.Cols:
  T.CLeaf{Sum.of_col(col), col}

def node(+l: T.Cols, +r: T.Cols) -> T.Cols:
  T.CNode{Sum.join(sum(l), sum(r)), l, r}

def flat_build(+depth: Nat, +x0: U32, +size: U32, +px: F32, +py: F32, +dirx: F32, +diry: F32, +plx: F32, +ply: F32, +ghost: T.Ghost, +blue: T.Portal, +orange: T.Portal, +hor: F32, +eye: F32, +sc: F32, +feet: F32, +w: U32) -> T.Cols:
  match depth:
    case 0n:
      leaf(Col.at(U32.is_lt(x0, w), (x0 + 1 : U32), w, px, py, dirx, diry, plx, ply, ghost, blue, orange, hor, eye, sc, feet))
    case 1n+d:
      +half = U32.shr(size)
      l = flat_build(d, x0, half, px, py, dirx, diry, plx, ply, ghost, blue, orange, hor, eye, sc, feet, w)
      r = flat_build(d, (x0 + half : U32), half, px, py, dirx, diry, plx, ply, ghost, blue, orange, hor, eye, sc, feet, w)
      node(l, r)

# One leaf for each pair of pixel columns. The halves fork down to strips of 16 px (8 pairs), then run in sequence.
def build(+depth: Nat, tiny: Bool, +x0: U32, +size: U32, +px: F32, +py: F32, +dirx: F32, +diry: F32, +plx: F32, +ply: F32, +ghost: T.Ghost, +blue: T.Portal, +orange: T.Portal, +hor: F32, +eye: F32, +sc: F32, +feet: F32, +w: U32) -> T.Cols:
  match depth tiny:
    case _ True{}:
      flat_build(depth, x0, size, px, py, dirx, diry, plx, ply, ghost, blue, orange, hor, eye, sc, feet, w)
    case 0n False{}:
      leaf(Col.at(U32.is_lt(x0, w), (x0 + 1 : U32), w, px, py, dirx, diry, plx, ply, ghost, blue, orange, hor, eye, sc, feet))
    case 1n+d False{}:
      +half = U32.shr(size)
      +tiny_next = U32.is_le(half, 16)
      l r = build(d, tiny_next, x0, half, px, py, dirx, diry, plx, ply, ghost, blue, orange, hor, eye, sc, feet, w) build(d, tiny_next, (x0 + half : U32), half, px, py, dirx, diry, plx, ply, ghost, blue, orange, hor, eye, sc, feet, w)
      node(l, r)
