import Base
import ../core/config.bend as C
import ../core/types.bend as T
import ../core/num.bend as Num
import ../world/level.bend as Level
import ../world/portals.bend as Portal
import ./keys.bend as Keys
import ./gun.bend as Gun
import ./move.bend as Move

# One game frame: first the events (keys, mouse, shots), then the physics.

def initial() -> T.GameState:
  T.GameState{T.Body{3.5, 3.5, 0.0, 0.0, 0.0, 0.0}, T.Look{0.0, 0.0, 0.0}, Keys.none(), T.Screen{C.W(), C.H()}, Portal.off(), Portal.off(), False{}, 0.0}

# ===== Events =====

def shoot(state: T.GameState, +fb: Bool, +fo: Bool) -> T.GameState:
  match state:
    case T.GameState{T.Body{+x, +y, +z, vx, vy, vz}, T.Look{+ang, +pitch, bob}, keys, screen, +blue, +orange, won, clock}:
      +hor = (C.HALF_H() + pitch : F32)
      +eye = (0.5 + z : F32)
      nb = Bool.pick(T.Portal, fb, Gun.fire(x, y, ang, hor, eye, blue, orange, True{}), blue)
      no = Bool.pick(T.Portal, fo, Gun.fire(x, y, ang, hor, eye, blue, orange, False{}), orange)
      T.GameState{T.Body{x, y, z, vx, vy, vz}, T.Look{ang, pitch, bob}, keys, screen, nb, no, won, clock}

def with_keys(state: T.GameState, +code: U32, +down: Bool) -> T.GameState:
  match state:
    case T.GameState{body, look, keys, screen, blue, orange, won, clock}:
      T.GameState{body, look, Keys.set(keys, code, down), screen, blue, orange, won, clock}

# q=113 blue, e=101 orange, r=114 restart
def key(state: T.GameState, +code: U32, +down: Bool) -> T.GameState:
  +fb = Bool.and(down, U32.is_eq(code, 113))
  +fo = Bool.and(down, U32.is_eq(code, 101))
  next = shoot(with_keys(state, code, down), fb, fo)
  Bool.pick(T.GameState, Bool.and(down, U32.is_eq(code, 114)), initial(), next)

# button 0 = left (blue), 1 = right (orange)
def click(state: T.GameState, +button: U32, +down: Bool) -> T.GameState:
  shoot(state, Bool.and(down, U32.is_eq(button, 0)), Bool.and(down, U32.is_eq(button, 1)))

# One window frame: the current size, and how far the mouse moved from the center.
# Without focus, the mouse is free and all keys are released, so no key stays down when you come back.
def sense(state: T.GameState, +w: U32, +h: U32, dx: U32, dy: U32, +focused: Bool) -> T.GameState:
  match state:
    case T.GameState{body, T.Look{ang, pitch, bob}, keys, screen, blue, orange, won, clock}:
      yaw = ((U32.to_f32(dx) - 32768.0) * C.YAW_PER_PX() : F32)
      tilt = ((U32.to_f32(dy) - 32768.0) * C.PITCH_PER_PX() : F32)
      npitch = F32.clamp((pitch - tilt : F32), F32.neg(C.PITCH_MAX()), C.PITCH_MAX())
      held = Bool.pick(T.Keys, focused, keys, Keys.none())
      T.GameState{body, T.Look{Num.wrap((ang + yaw : F32)), npitch, bob}, held, T.Screen{w, h}, blue, orange, won, clock}

def event(e: Event, state: T.GameState) -> T.GameState:
  match e:
    case Key{code, down}:
      key(state, code, down)
    case Mouse{x, y, button, down}:
      click(state, button, down)
    case Move{x, y}:
      state
    case Close{}:
      state

# Esc = 27
def is_quit(e: Event) -> Bool:
  match e:
    case Close{}:
      True{}
    case Key{code, down}:
      Bool.and(down, U32.is_eq(code, 27))
    case Mouse{x, y, button, down}:
      False{}
    case Move{x, y}:
      False{}

def fold(events: List<Event>, state: T.GameState) -> Maybe<T.GameState>:
  match events:
    case Nil{}:
      Some{state}
    case +h <> t:
      rest = fold(t, event(h, state))
      Bool.pick(Maybe<T.GameState>, is_quit(h), None{}, rest)

# ===== Physics =====

# A wall sets the speed on its axis to zero. A portal turns the remaining speed, so momentum goes through.
# After a crossing, the exit has a minimum speed out of the wall, and the total speed has a limit.
def settle(step: T.Step, vx: F32, vy: F32, z: F32, vz: F32, ang: F32, pitch: F32, bob: F32, keys: T.Keys, screen: T.Screen, blue: T.Portal, orange: T.Portal, won: Bool, clock: F32) -> T.GameState:
  match step:
    case T.Step{+x, +y, +rot, hitx, hity, +nx, +ny}:
      +ux = Bool.pick(F32, hitx, 0.0, vx)
      +uy = Bool.pick(F32, hity, 0.0, vy)
      +c = F32.cos(rot)
      +s = F32.sin(rot)
      +rvx = (c * ux - s * uy : F32)
      +rvy = (s * ux + c * uy : F32)
      +boost = F32.max((C.EXIT_SPEED() - (rvx * nx + rvy * ny) : F32), 0.0)
      +bvx = (rvx + nx * boost : F32)
      +bvy = (rvy + ny * boost : F32)
      +cap = F32.min((C.MAX_SPEED() / F32.max(F32.hypot(bvx, bvy), 0.0001) : F32), 1.0)
      T.GameState{T.Body{x, y, z, (bvx * cap : F32), (bvy * cap : F32), vz}, T.Look{Num.wrap((ang + rot : F32)), pitch, bob}, keys, screen, blue, orange, Bool.or(won, Level.near_exit(x, y)), Num.wrap((clock + C.CLOCK_RATE() : F32))}

def move(state: T.GameState) -> T.GameState:
  match state:
    case T.GameState{T.Body{+x, +y, +z, vx, vy, vz}, T.Look{ang, pitch, bob}, +keys, screen, +blue, +orange, won, clock}:
      +na = Num.wrap((ang + Keys.turn(keys) * C.TURN() : F32))
      np = F32.clamp((pitch + Keys.pitch(keys) * C.PITCH_RATE() : F32), F32.neg(C.PITCH_MAX()), C.PITCH_MAX())
      +c = F32.cos(na)
      +s = F32.sin(na)
      +fw = Keys.forward(keys)
      +st = Keys.strafe(keys)
      diagonal = Bool.and(F32.is_ne(fw, 0.0), F32.is_ne(st, 0.0))
      +grounded = F32.is_le(z, 0.0)
      +acc = (Bool.pick(F32, grounded, C.ACCEL(), C.AIR_ACCEL()) * Bool.pick(F32, diagonal, 0.7071, 1.0) : F32)
      +fric = Bool.pick(F32, grounded, C.FRICTION(), C.AIR_FRICTION())
      +wvx = ((vx + (c * fw - s * st) * acc) * fric : F32)
      +wvy = ((vy + (s * fw + c * st) * acc) * fric : F32)
      +open = Bool.and(Portal.is_on(blue), Portal.is_on(orange))
      +nvx = (wvx + Move.funnel(blue, open, x, y, wvx, wvy, True{}) + Move.funnel(orange, open, x, y, wvx, wvy, True{}) : F32)
      +nvy = (wvy + Move.funnel(blue, open, x, y, wvx, wvy, False{}) + Move.funnel(orange, open, x, y, wvx, wvy, False{}) : F32)
      +vz1 = Bool.pick(F32, Bool.and(grounded, Keys.jump(keys)), C.JUMP(), (vz - C.GRAVITY() : F32))
      +z1 = (z + vz1 : F32)
      +landed = F32.is_le(z1, 0.0)
      +bumped = F32.is_ge(z1, C.Z_MAX())
      nz = Bool.pick(F32, landed, 0.0, Bool.pick(F32, bumped, C.Z_MAX(), z1))
      nvz = Bool.pick(F32, Bool.or(landed, bumped), 0.0, vz1)
      nbob = Num.wrap((bob + Bool.pick(F32, grounded, F32.hypot(nvx, nvy), 0.0) * 3.2 : F32))
      settle(Move.both(x, y, nvx, nvy, blue, orange), nvx, nvy, nz, nvz, na, np, nbob, keys, screen, blue, orange, won, clock)

def after(m: Maybe<T.GameState>) -> Maybe<T.GameState>:
  match m:
    case None{}:
      None{}
    case Some{s}:
      Some{move(s)}
