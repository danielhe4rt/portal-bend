import Base
import ../game/core/types.bend as T
import ../game/render/view.bend as View

# Scene: open room, both portals open, the camera turns and looks up and down.
# Renders 300 frames as the game does: one bang per frame, an IO step between frames, the last frame dropped.
# Prints the total ms. Run it as the game runs: --gpu off --threads 4.

def frame(+t: F32) -> Image:
  View.frame!(3.5, 3.5, (t * 0.1 : F32), (360.0 + F32.sin((t * 0.05 : F32)) * 200.0 : F32), (0.5 + F32.abs(F32.sin((t * 0.1 : F32))) * 0.35 : F32), 0.0, (t * 0.09 : F32), T.Portal{True{}, 15, 4, 0}, T.Portal{True{}, 0, 2, 1}, False{}, 1280, 720)

def loop(+n: Nat, +t0: Nat, old: Image) -> IO(Unit):
  match n:
    case 0n:
      do IO<Unit>:
        t1 : Nat <- IO.now()
        Unit <- IO.pure(Unit, Image.drop(old))
        IO.print("ms " ++ U32.show(U32.from_nat(Nat.sub(t1, t0))))
    case 1n+p:
      do IO<Unit>:
        now : Nat <- IO.now()
        Unit <- IO.pure(Unit, Image.drop(old))
        img : Image <- IO.pure(Image, frame(U32.to_f32(U32.from_nat(p))))
        loop(p, t0, img)

def main() -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    loop(300n, t0, Pix{0})
