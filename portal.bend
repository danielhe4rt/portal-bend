import Base
import ./game/core/config.bend as C
import ./game/core/types.bend as T
import ./game/render/view.bend as View
import ./game/play/tick.bend as Tick
import ./game/host/screen.bend as Host

# Portal in Bend: a DDA raycaster with portals that the player places.
# Controls: W/S move, A/D strafe, Space jumps,
# mouse (held at the center while the window has focus) or arrow keys turn and tilt the camera,
# Q or left button = blue portal, E or right button = orange portal,
# R restarts, Esc quits.
#
# Module map:
#   game/core    config (constants), types (data), num (small math)
#   game/world   level (map), face and portals (geometry), ray (raycast through portals), ghost (body and clone)
#   game/render  proj, color, col and cols (columns), summary, shade (pixel), view (frame quadtree)
#   game/play    keys, gun, move (collision and crossing), tick (events and physics)
#   game/host    screen (window size, tiling and mouse capture, in C)

# Each frame: read the window (size, mouse, focus), draw, then apply the events and the physics.
# The loop gives the next frame as "rest", because a def can only call the defs above it.
# The frame is one bang: only a bang spreads the render over the thread pool (play.sh runs it with --gpu off).
# Screen.sync is the IO step between the physics and the bang, so the bang does not run inline.

def Game.view(s: T.GameState) -> T.GameState & Image:
  match s:
    case T.GameState{+body, +look, keys, +screen, +blue, +orange, +won, +clock}:
      img = View.of!(body, look, blue, orange, won, clock, screen)
      (T.GameState{body, look, keys, screen, blue, orange, won, clock}, img)

def Game.next(window: Window, next: Maybe<T.GameState>, rest: Window -> T.GameState -> IO(Unit)) -> IO(Unit):
  match next:
    case None{}:
      Window.close(window)
    case Some{state}:
      rest(window, state)

def Game.turn(shown: Window & Image & List<Event>, state: T.GameState, rest: Window -> T.GameState -> IO(Unit)) -> IO(Unit):
  (window, image, events) = shown
  do IO<Unit>:
    Unit <- IO.pure(Unit, Image.drop!(image))
    Game.next(window, Tick.after(Tick.fold(events, state)), rest)

def Game.draw(window: Window, drawn: T.GameState & Image, rest: Window -> T.GameState -> IO(Unit)) -> IO(Unit):
  (state, image) = drawn
  do IO<Unit>:
    shown : Window & Image & List<Event> <- Window.frame(window, image)
    Game.turn(shown, state, rest)

def Game.step(got: Window & U32 & U32 & U32 & U32 & U32, state: T.GameState, rest: Window -> T.GameState -> IO(Unit)) -> IO(Unit):
  (window, w, h, dx, dy, focused) = got
  Game.draw(window, Game.view(Tick.sense(state, w, h, dx, dy, U32.is_eq(focused, 1))), rest)

def Game.loop(fuel: Nat, window: Window, state: T.GameState) -> IO(Unit):
  match fuel:
    case 0n:
      Window.close(window)
    case 1n+f:
      do IO<Unit>:
        got : Window & U32 & U32 & U32 & U32 & U32 <- Host.Screen.sync(window)
        Game.step(got, state, w => s => Game.loop(f, w, s))

def main() -> IO(Unit):
  do IO<Unit>:
    opened : Window <- IO.try(Window, Window.open("Portal - Bend", C.W(), C.H()))
    window : Window <- Host.Screen.setup(opened)
    Game.loop(U32.to_nat(4294967295), window, Tick.initial())
