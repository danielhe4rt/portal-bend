import Base
import ../core/types.bend as T
import ../core/num.bend as Num

# Keys held down. Codes: w=119 a=97 s=115 d=100 space=32,
# arrows: up=63232 down=63233 left=63234 right=63235.

def none() -> T.Keys:
  T.Keys{False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}

def set(keys: T.Keys, +code: U32, +down: Bool) -> T.Keys:
  match keys:
    case T.Keys{w, a, s, d, left, right, up, dn, space}:
      T.Keys{Bool.pick(Bool, U32.is_eq(code, 119), down, w), Bool.pick(Bool, U32.is_eq(code, 97), down, a), Bool.pick(Bool, U32.is_eq(code, 115), down, s), Bool.pick(Bool, U32.is_eq(code, 100), down, d), Bool.pick(Bool, U32.is_eq(code, 63234), down, left), Bool.pick(Bool, U32.is_eq(code, 63235), down, right), Bool.pick(Bool, U32.is_eq(code, 63232), down, up), Bool.pick(Bool, U32.is_eq(code, 63233), down, dn), Bool.pick(Bool, U32.is_eq(code, 32), down, space)}

def forward(k: T.Keys) -> F32:
  match k:
    case T.Keys{w, a, s, d, left, right, up, dn, space}:
      (Num.flag(w) - Num.flag(s) : F32)

def strafe(k: T.Keys) -> F32:
  match k:
    case T.Keys{w, a, s, d, left, right, up, dn, space}:
      (Num.flag(d) - Num.flag(a) : F32)

def turn(k: T.Keys) -> F32:
  match k:
    case T.Keys{w, a, s, d, left, right, up, dn, space}:
      (Num.flag(right) - Num.flag(left) : F32)

def pitch(k: T.Keys) -> F32:
  match k:
    case T.Keys{w, a, s, d, left, right, up, dn, space}:
      (Num.flag(up) - Num.flag(dn) : F32)

def jump(k: T.Keys) -> Bool:
  match k:
    case T.Keys{w, a, s, d, left, right, up, dn, space}:
      space
