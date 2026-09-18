import Base

# Print one frame as a pre-order tree for tests/snapshot.py:
# ./dump --gpu 4GB | python3 tests/snapshot.py <dir>
import ./ray.bend as R

def dump(img: Image) -> IO(Unit):
  match img:
    case Pix{c}:
      IO.print(U32.show(c))
    case Qua{a, b, c, d}:
      do IO<Unit>:
        IO.print("Q")
        dump(a)
        dump(b)
        dump(c)
        dump(d)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("# spike: tile renderer, frame 40")
    dump(R.show(R.cam_at(40.0), Pix{0}))
