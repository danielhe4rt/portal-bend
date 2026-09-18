import Base
import ./pixel.bend as P

# Render 10 frames of 1280x720 with one bang per frame and print a checksum.
def main() -> IO(Unit):
  IO.print(U32.show(P.loop_gpu(10n, 0)))
