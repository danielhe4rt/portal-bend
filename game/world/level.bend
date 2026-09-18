import Base
import ../core/config.bend as C

# The map, and the questions about cells.

# 0 = floor, 1 = panel (accepts portals), 2 = glass, 3 = exit, 4 = metal (refuses portals)
# The exit room accepts a portal only on the north wall: the shot through the glass must be at an angle.
#
#      x: 0 1 2 3 4 5 6 7 8 9 A B C D E F
#   y 0   1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#     1   1 . . . . . . 1 . . . . . . . 1
#     2   1 . . . . . . 1 . . . . . . . 1
#     3   1 . . . . . . 2 . . . . . . . 1
#     4   1 . . . . . . 2 . . . . . . . 1
#     5   1 . . . . . . 1 . . . . . . . 1
#     6   1 1 1 . 1 1 1 1 . . . . . . . 4
#     7   1 . . . . . . . . . . . . . . 4
#     8   1 . . . . . . . . . . . . . . 4
#     9   1 . . . . . . 1 1 1 1 1 1 1 1 1
#     A   1 . . . . . . 2 . . . . . . . 4
#     B   1 . . . . . . 2 . . . . . . . 4
#     C   1 . . . . . . 1 . . . . . . . 4
#     D   1 . . . . . . 1 . . . . 3 . . 4
#     E   1 . . . . . . 1 . . . . . . . 4
#     F   1 1 1 1 1 1 1 1 4 4 4 4 4 4 4 1
#
# Each row is one bit mask per cell kind: bit x is set when cell (x, y) has that kind.

def panels(+y: U32) -> U32:
  Bool.pick(U32, U32.is_eq(y, 0), 65535, Bool.pick(U32, U32.is_lt(y, 3), 32897, Bool.pick(U32, U32.is_lt(y, 5), 32769, Bool.pick(U32, U32.is_eq(y, 5), 32897,
  Bool.pick(U32, U32.is_eq(y, 6), 247, Bool.pick(U32, U32.is_lt(y, 9), 1, Bool.pick(U32, U32.is_eq(y, 9), 65409, Bool.pick(U32, U32.is_lt(y, 12), 1,
  Bool.pick(U32, U32.is_lt(y, 15), 129, 33023)))))))))

def glass(+y: U32) -> U32:
  Bool.pick(U32, Bool.or(U32.is_eq(y, 3), U32.is_eq(y, 4)), 128, Bool.pick(U32, Bool.or(U32.is_eq(y, 10), U32.is_eq(y, 11)), 128, 0))

def exits(+y: U32) -> U32:
  Bool.pick(U32, U32.is_eq(y, 13), 4096, 0)

def metal(+y: U32) -> U32:
  Bool.pick(U32, U32.is_lt(y, 6), 0, Bool.pick(U32, U32.is_eq(y, 9), 0, Bool.pick(U32, U32.is_eq(y, 15), 32512, 32768)))

def has(+row: U32, +x: U32) -> Bool:
  U32.is_ne(((row >> U32.to_nat(x)) .&. 1 : U32), 0)

# Outside the map is panel. A step left from x = 0 wraps to a large U32, so it is outside too.
def cell(+x: U32, +y: U32) -> U32:
  inside = Bool.and(U32.is_lt(x, 16), U32.is_lt(y, 16))
  kind = Bool.pick(U32, has(panels(y), x), 1, Bool.pick(U32, has(glass(y), x), 2, Bool.pick(U32, has(exits(y), x), 3, Bool.pick(U32, has(metal(y), x), 4, 0))))
  Bool.pick(U32, inside, kind, 1)

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
