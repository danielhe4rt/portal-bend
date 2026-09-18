import Base
import ../game/core/types.bend as T
import ../game/render/cols.bend as Cols
import ../game/world/ghost.bend as Ghost

def low(s: T.Sum) -> F32:
  match s:
    case T.Sum{lo, f0, f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15, f16, f17, f18, f19, f20, f21, f22, f23, f24}:
      lo

def loop(+n: Nat, acc: F32) -> F32:
  match n:
    case 0n:
      acc
    case 1n+p:
      +t = U32.to_f32(U32.from_nat(p))
      +dirx = F32.cos((t * 0.1 : F32))
      +diry = F32.sin((t * 0.1 : F32))
      cols = Cols.build(10n, 0, 2048, 3.5, 3.5, dirx, diry, (F32.neg(diry) * 0.8 : F32), (dirx * 0.8 : F32), Ghost.of(3.5, 3.5, T.Portal{False{}, 15, 4, 0}, T.Portal{False{}, 0, 2, 1}), T.Portal{False{}, 15, 4, 0}, T.Portal{False{}, 0, 2, 1}, 360.0, 0.5, 800.0, 0.0, 1280)
      loop(p, (acc + low(Cols.sum(cols)) : F32))

def report(n: Nat) -> String:
  F32.show(loop(n, 0.0))

def main() -> IO(Unit):
  IO.print(report(300n))
