import Base

def frac(+x: F32) -> F32:
  (x - F32.floor(x) : F32)

# Vertical seam between panels: two for each cell.
def seam(u: F32) -> Bool:
  +q = frac((u * 2.0 : F32))
  Bool.or(F32.is_lt(q, 0.03), F32.is_gt(q, 0.97))

def wrap(+a: F32) -> F32:
  +tau = (F32.pi() * 2.0 : F32)
  Bool.pick(F32, F32.is_gt(a, F32.pi()), (a - tau : F32), Bool.pick(F32, F32.is_lt(a, F32.neg(F32.pi())), (a + tau : F32), a))

def flag(b: Bool) -> F32:
  Bool.pick(F32, b, 1.0, 0.0)
