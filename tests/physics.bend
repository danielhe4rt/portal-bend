import Base
import ../game/core/types.bend as T
import ../game/play/tick.bend as Tick

# Run the physics without a window and print the body each frame.

def show(s: T.GameState) -> String:
  match s:
    case T.GameState{T.Body{x, y, z, vx, vy, vz}, T.Look{ang, pitch, bob}, keys, ptr, blue, orange, won, clock}:
      "pos " ++ F32.show(x) ++ " " ++ F32.show(y) ++ " z " ++ F32.show(z) ++ " vel " ++ F32.show(vx) ++ " " ++ F32.show(vy) ++ " ang " ++ F32.show(ang)

def run(n: Nat, +s: T.GameState) -> IO(Unit):
  match n:
    case 0n:
      IO.print(show(s))
    case 1n+p:
      do IO<Unit>:
        IO.print(show(s))
        run(p, Tick.move(s))

def walking(x: F32, y: F32, ang: F32, +jump: Bool, blue: T.Portal, orange: T.Portal) -> T.GameState:
  T.GameState{T.Body{x, y, 0.0, 0.0, 0.0, 0.0}, T.Look{ang, 0.0, 0.0}, T.Keys{Bool.not(jump), False{}, False{}, False{}, False{}, False{}, False{}, False{}, jump}, T.Screen{1280, 720}, blue, orange, False{}, 0.0}

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("--- A: jump in place ---")
    run(34n, walking(3.5, 3.5, 0.0, True{}, T.Portal{False{}, 0, 0, 0}, T.Portal{False{}, 0, 0, 0}))
    IO.print("--- B: W to the glass at x=7 ---")
    run(70n, walking(3.5, 3.5, 0.0, False{}, T.Portal{False{}, 0, 0, 0}, T.Portal{False{}, 0, 0, 0}))
    IO.print("--- C: continuous crossing (7,2,west) -> (10,9,south) ---")
    run(40n, walking(5.5, 2.5, 0.0, False{}, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 10, 9, 3}))
    IO.print("--- D: corner: move up in y along the wall (7,5)/(7,6) ---")
    run(30n, walking(8.1, 7.5, F32.neg(1.5707964), False{}, T.Portal{False{}, 0, 0, 0}, T.Portal{False{}, 0, 0, 0}))
    IO.print("--- E: funneling: enter 0.4 off the center of the mouth ---")
    run(40n, walking(5.5, 2.9, 0.0, False{}, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 10, 9, 3}))
    IO.print("--- F: without an open pair, the portal is a wall ---")
    run(30n, walking(5.5, 2.5, 0.0, False{}, T.Portal{True{}, 7, 2, 0}, T.Portal{False{}, 0, 0, 0}))
    IO.print("--- G: enter 0.45 off center: funneling must fit the body in the ellipse ---")
    run(40n, walking(5.5, 2.95, 0.0, False{}, T.Portal{True{}, 7, 2, 0}, T.Portal{True{}, 10, 9, 3}))
