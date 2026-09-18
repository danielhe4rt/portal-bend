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
      img = View.frame(6.2, 2.5, (t * 0.001 : F32), 360.0, 0.5, 0.0, (t * 0.09 : F32), T.Portal{True{}, 0, 3, 1}, T.Portal{True{}, 7, 2, 0}, False{}, 1280, 720)
      loop(p, (acc + sum(img) : U32))

# The evaluated root must reach a fork: with U32.show at the root, the runtime uses one thread only.
def report(n: Nat) -> String:
  U32.show(loop(n, 0))

def main() -> IO(Unit):
  IO.print(report(300n))
