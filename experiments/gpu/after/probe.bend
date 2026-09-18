import Base

# Render 300 frames without a window, with IO.now between the frames, and print the total ms.
# Usage: ./probe --gpu 4GB   or   ./probe --gpu off --threads 4
import ./ray.bend as R

def sum(img: Image) -> U32:
  match img:
    case Pix{c}:
      (c .&. 255 : U32)
    case Qua{a, b, c, d}:
      (sum(a) + sum(b) + sum(c) + sum(d) : U32)

def count(img: Image) -> U32:
  match img:
    case Pix{c}:
      1
    case Qua{a, b, c, d}:
      (count(a) + count(b) + count(c) + count(d) : U32)

def done(+t0: Nat, +t1: Nat, img: Image) -> IO(Unit):
  IO.print("ms " ++ U32.show(U32.from_nat(Nat.sub(t1, t0))) ++ " leaves " ++ U32.show(count(img)))

def loop(+n: Nat, +t0: Nat, old: Image) -> IO(Unit):
  match n:
    case 0n:
      do IO<Unit>:
        t1 : Nat <- IO.now()
        done(t0, t1, old)
    case 1n+p:
      do IO<Unit>:
        now : Nat <- IO.now()
        img : Image <- IO.pure(Image, R.show(R.cam_at(U32.to_f32(U32.from_nat(p))), old))
        loop(p, t0, img)

def main() -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    loop(300n, t0, Pix{0})
