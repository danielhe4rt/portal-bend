import Base

# All game data in one place.

# ===== World =====

# face: 0 = west, 1 = east, 2 = north, 3 = south (side of the wall cell)
type Portal is Data:
  Portal{on: Bool, cx: U32, cy: U32, face: U32}

# One ray segment: from the origin (ox, oy) in the direction (dx, dy) to the wall, at t.
# which: 0 = plain wall, 1 = blue portal, 2 = orange portal
type Hit is Data:
  Hit{t: F32, cx: U32, cy: U32, face: U32, code: U32, u: F32, glass: Bool, through: Bool, which: U32, ox: F32, oy: F32, dx: F32, dy: F32}

# The player body for the render: the original, and the clone on the other side of the portal it crosses.
# Each one shows only in front of its clip plane (point a, normal an; point b, normal bn).
# Far from the portals, the normal of the original is zero (no clip) and the clone is off.
type Ghost is Data:
  Ghost{x: F32, y: F32, ax: F32, ay: F32, anx: F32, any: F32, clone: Bool, cx: F32, cy: F32, bx: F32, by: F32, bnx: F32, bny: F32}

# ===== Screen =====

# The player body seen in one ray segment, after projection: u = lateral position on the body (-1 to 1).
type Figure is Data:
  Figure{on: Bool, top: F32, bot: F32, u: F32, fog: F32}

# The original and the clone can show in the same ray segment: near is drawn over far.
type Bodies is Data:
  Bodies{near: Figure, far: Figure}

# What one pixel column shows, from near to far.
# Gate = wall with a portal: in the ellipse, "next" shows what the ray sees when it leaves the other portal.
# Wall = where the ray stops. body = the player seen in the segment that ends at this node.
type Seen is Data:
  Wall{top: F32, bot: F32, c: U32, l: U32, seam: Bool, tiled: Bool, body: Bodies}
  Gate{top: F32, bot: F32, u: F32, c: U32, l: U32, seam: Bool, pc: U32, open: Bool, body: Bodies, next: Seen}

# Summary of a range of columns: it tells which screen blocks have one color only. All values are pixel rows.
#   front (first node of the chain): lo, hi = lowest top and highest bottom; ftmax, fbmin = highest top and lowest bottom
#   front portal ellipse:            etop, ebot = rows that an ellipse touches (outside of them, the front wall shows)
#   front portal ring:               rtop..rarc_top and rarc_bot..rbot = rows that are solid ring in all columns
#   front portal core:               gtop, gbot = rows inside all front ellipses; mlo, mhi = the second node
#   clear window:                    wtop, wbot = rows inside the ellipses of the full chain, where only the back shows
#   back (last node of the chain):   blo, bhi, btmax, bbmin
type Sum is Data:
  Sum{lo: F32, hi: F32, ftmax: F32, fbmin: F32, fc: U32, fplain: Bool, etop: F32, ebot: F32, rtop: F32, rarc_top: F32, rarc_bot: F32, rbot: F32, pc: U32, pplain: Bool, gtop: F32, gbot: F32, mlo: F32, mhi: F32, wtop: F32, wbot: F32, blo: F32, bhi: F32, btmax: F32, bbmin: F32, bc: U32, bplain: Bool}

# Binary tree of columns. A leaf keeps the same summary type as a node, calculated one time for each column.
type Cols is Data:
  CLeaf{sum: Sum, col: Seen}
  CNode{sum: Sum, l: Cols, r: Cols}

# ===== Player =====

# Result of one step: (nx, ny) is the normal of the exit portal, or zero if there is no crossing.
type Step is Data:
  Step{x: F32, y: F32, rot: F32, hitx: Bool, hity: Bool, nx: F32, ny: F32}

# z = height of the feet above the floor
type Body is Data:
  Body{x: F32, y: F32, z: F32, vx: F32, vy: F32, vz: F32}

# pitch = horizon offset in pixels (a positive value looks up)
type Look is Data:
  Look{ang: F32, pitch: F32, bob: F32}

# Window size in pixels, read each frame: the window can tile and change size.
type Screen is Data:
  Screen{w: U32, h: U32}

type Keys is Data:
  Keys{w: Bool, a: Bool, s: Bool, d: Bool, left: Bool, right: Bool, up: Bool, down: Bool, jump: Bool}

type GameState is Data:
  GameState{body: Body, look: Look, keys: Keys, screen: Screen, blue: Portal, orange: Portal, won: Bool, clock: F32}
