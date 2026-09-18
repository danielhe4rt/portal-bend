import Base
import ../game/core/types.bend as T
import ../game/render/view.bend as View

# Print the quadtree of each scene in pre-order ("Q" or the color). tests/snapshot.py makes the PNGs.

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
    IO.print("# mirror: portals face to face, the player sees their own back")
    dump(View.frame(3.5, 2.5, 0.0, 360.0, 0.5, 0.0, 1.0, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 0, 2, 1}, False{}, 1280, 720))
    IO.print("# jump: same place, at the top of the jump, looking to the side")
    dump(View.frame(4.5, 2.3, 0.35, 330.0, 0.85, 0.35, 2.5, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 0, 2, 1}, False{}, 1280, 720))
    IO.print("# metal: wall that refuses portals, unpaired orange portal next to it")
    dump(View.frame(11.5, 6.5, 0.0, 360.0, 0.5, 0.0, 0.0, T.Portal{False{}, 0, 0, 0}, T.Portal{True{}, 15, 5, 0}, False{}, 1280, 720))
    IO.print("# before: 0.03 before the blue portal plane")
    dump(View.frame(6.97, 2.5, 0.0, 360.0, 0.5, 0.0, 0.0, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 10, 9, 3}, False{}, 1280, 720))
    IO.print("# after: 0.03 after, already at the orange portal")
    dump(View.frame(10.5, 10.03, 1.5707964, 360.0, 0.5, 0.0, 0.0, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 10, 9, 3}, False{}, 1280, 720))
    IO.print("# close: against the orange portal, seeing yourself through the blue one")
    dump(View.frame(6.2, 2.5, 0.0, 360.0, 0.5, 0.0, 1.0, T.Portal{True{}, 0, 3, 1}, T.Portal{True{}, 7, 2, 0}, False{}, 1280, 720))
    IO.print("# crossing_front: half body in the blue portal, looking at the orange one on the opposite wall")
    dump(View.frame(6.9, 2.5, 3.1415927, 360.0, 0.5, 0.0, 1.0, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 0, 2, 1}, False{}, 1280, 720))
    IO.print("# crossing_front@960x1000: tall tile (half of a 1920x1080 monitor)")
    dump(View.frame(6.9, 2.5, 3.1415927, 500.0, 0.5, 0.0, 1.0, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 0, 2, 1}, False{}, 960, 1000))
    IO.print("# crossing_front@1920x1080: full screen 1080p")
    dump(View.frame(6.9, 2.5, 3.1415927, 540.0, 0.5, 0.0, 1.0, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 0, 2, 1}, False{}, 1920, 1080))
    IO.print("# crossing_front@2560x720: wide tile, shows more to the sides")
    dump(View.frame(6.9, 2.5, 3.1415927, 360.0, 0.5, 0.0, 1.0, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 0, 2, 1}, False{}, 2560, 720))
    IO.print("# crossing_side: half body in the blue portal, looking at the orange one on another wall")
    dump(View.frame(6.9, 2.5, 2.17, 360.0, 0.5, 0.0, 1.0, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 4, 6, 2}, False{}, 1280, 720))
    IO.print("# crossing_end: center 0.1 past the plane, already teleported to the orange portal")
    dump(View.frame(1.1, 2.5, 0.0, 360.0, 0.5, 0.0, 1.0, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 0, 2, 1}, False{}, 1280, 720))
    IO.print("# crossing_corner: in the mouth of the blue portal (left wall), looking at the orange one on the front wall")
    dump(View.frame(1.1, 5.4, 0.5, 360.0, 0.5, 0.0, 1.0, T.Portal{True{}, 0, 5, 1}, T.Portal{True{}, 2, 6, 2}, False{}, 1280, 720))
