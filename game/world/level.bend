import Base
import ../core/config.bend as C

# The map, and the questions about cells.

# 0 = floor, 1 = panel (accepts portals), 2 = glass, 3 = exit, 4 = metal (refuses portals)
# The exit room accepts a portal only on the north wall: the shot through the glass must be at an angle.
def rows() -> +List<+List<U32>>:
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 4],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4],
    [1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 4],
    [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 4],
    [1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4],
    [1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 3, 0, 0, 4],
    [1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4],
    [1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 4, 1]
  ]

def get(-A: Data, xs: +List<A>, +i: U32, +k: U32, +d: A) -> A:
  match xs:
    case Nil{}:
      d
    case h <> t:
      Bool.pick(A, U32.is_eq(i, k), h, get(A, t, i, (k + 1 : U32), d))

def cell(+x: U32, +y: U32) -> U32:
  row = get(+List<U32>, rows(), y, 0, [])
  get(U32, row, x, 0, 1)

# Glass lets the ray through. Panel, exit and metal stop the ray.
def stops_ray(+code: U32) -> Bool:
  Bool.or(U32.is_eq(code, 1), Bool.or(U32.is_eq(code, 3), U32.is_eq(code, 4)))

def is_exit(x: F32, y: F32) -> Bool:
  U32.is_eq(cell(F32.to_u32(F32.floor(x)), F32.to_u32(F32.floor(y))), 3)

def near_exit(+x: F32, +y: F32) -> Bool:
  +reach = (C.RADIUS() * 2.0 : F32)
  side = Bool.or(is_exit((x + reach : F32), y), is_exit((x - reach : F32), y))
  ends = Bool.or(is_exit(x, (y + reach : F32)), is_exit(x, (y - reach : F32)))
  Bool.or(side, ends)
