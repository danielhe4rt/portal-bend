import Base
import ../game/core/types.bend as T
import ../game/render/view.bend as View

# Render 300 frames without a window and add the colors: this measures only the render cost.

def sum(img: Image) -> U32:
  match img:
    case Pix{c}:
      c
    case Qua{a, b, c, d}:
      (sum(a) + sum(b) + sum(c) + sum(d) : U32)

def loop(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      +t = U32.to_f32(U32.from_nat(p))
      img = View.frame(3.5, 3.5, (t * 0.1 : F32), (360.0 + F32.sin((t * 0.05 : F32)) * 200.0 : F32), (0.5 + F32.abs(F32.sin((t * 0.1 : F32))) * 0.35 : F32), 0.0, (t * 0.09 : F32), T.Portal{False{}, 15, 4, 0}, T.Portal{False{}, 0, 2, 1}, False{}, 1280, 720)
      loop(p, (acc + sum(img) : U32))

# The evaluated root must reach a fork: with U32.show at the root, the runtime uses one thread only.
def report(n: Nat) -> String:
  U32.show(loop(n, 0))

def main() -> IO(Unit):
  IO.print(report(300n))
