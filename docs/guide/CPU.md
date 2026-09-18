# SHADERS.md on the CPU: what paid off in portal-bend

> The follow-up to [GPU.md](GPU.md). On our machine the GPU loses to the CPU pool, so we took the rules of `SHADERS.md` and tried each one on the **real game renderer** (portals, body clone, floor bands, crosshair), running on the CPU. Some paid off BIG, some made it slower, and one finding changed how we think about Bend's parallelism.

**TL;DR**

| Worst case (camera against a portal, seeing yourself) | Before | After | |
|---|---|---|---|
| 1280x720 | 12.01 ms | **7.10 ms** | 1.7x |
| 1920x1080 | 24.95 ms | **14.32 ms** | 1.7x, now inside 60 FPS |
| 2560x1440 | 44.21 ms | **23.22 ms** | 1.9x, still above 16.7 ms |

- **The render never used more than one thread.** The forks in our renderer ran on one core: 11.2 ms at 1, 4 and 16 threads. A parallel let outside a bang does not reach the pool. **One bang per frame** is what turns the forks into real parallelism, even with `--gpu off`.
- **A bang alone made things worse.** With a fork at every `Qua`, the normal scene went from 2.6 to 4.4 ms. The bang pays off only together with the guide's other rule: **fork down to 16-px blocks, then build in sequence**.
- **The map as bit masks** (the guide's "tables are word chains") gave 8-15% by itself.
- **Two rules did not pay off here:** the typed `pick` was 13% SLOWER on the CPU, and a direct port to the 16-px tile renderer was 2.4x slower in normal scenes.
- Every step kept the pixels: the physics trace and all 13 snapshot PNGs are byte-identical before and after.

---

## Contents

1. [Setup and method](#1-setup-and-method)
2. [Step by step](#2-step-by-step)
3. [The final numbers](#3-the-final-numbers)
4. [Thread scaling](#4-thread-scaling)
5. [What is still slow](#5-what-is-still-slow)
6. [New nitpicks](#6-new-nitpicks)
7. [New questions for the Bend team](#7-new-questions-for-the-bend-team)
8. [Reproduce it](#8-reproduce-it)

---

## 1. Setup and method

Same machine as [GPU.md](GPU.md#1-the-setup): Ryzen 9 7950X, RTX 4060 (unused here), Bend 2.0.10, `--threads 4` unless stated.

Four scenes, 300 frames each, the camera moving a little every frame:

| Scene | What it shows |
|---|---|
| `bench` | an open room, both portals open, the camera turns and looks up and down |
| `bench_noportal` | the same room, no portals |
| `bench_mouth` | standing in the mouth of the blue portal, looking through it |
| `bench_close` | against the orange portal, seeing yourself through the blue one: **the worst case**, because the body turns off the quadtree compression in its columns |

Every change was checked two ways before any timing:

- `tests/physics.bend` prints the body every frame: the output must be **identical** to the last commit.
- `tests/snapshot.bend` renders 13 scenes (mirror, jump, portal crossings, 3 window sizes): every PNG must be **byte-identical** to the last commit.

Timings compare interleaved runs (A, B, A, B...) of binaries built from the same source tree.

---

## 2. Step by step

```text
  step                               720p worst case   kept?
  ─────────────────────────────────  ────────────────  ─────
  0  last commit                       12.0 ms
  1  map as bit masks                  11.1 ms          yes
  2  typed pick / word                 12.9 ms          NO  (13% slower)
  3  direct port to 16-px tiles         9.9 ms          NO  (2.4x slower in normal scenes)
  4  forks only down to 16 px          11.9 ms          yes (it only pays off with 5)
  5  one bang per frame                 7.1 ms          yes
```

### 2.1 The map as bit masks (kept)

The map was a list of lists, walked on every DDA step and every collision test.

```python
# BEFORE: a List walk per cell
def cell(+x: U32, +y: U32) -> U32:
  row = get(+List<U32>, rows(), y, 0, [])
  get(U32, row, x, 0, 1)

# AFTER: one U32 per row for each cell kind, and a native shift
def panels(+y: U32) -> U32:
  Bool.pick(U32, U32.is_eq(y, 0), 65535, Bool.pick(U32, U32.is_lt(y, 3), 32897, ...))

def has(+row: U32, +x: U32) -> Bool:
  U32.is_ne(((row >> U32.to_nat(x)) .&. 1 : U32), 0)

def cell(+x: U32, +y: U32) -> U32:
  inside = Bool.and(U32.is_lt(x, 16), U32.is_lt(y, 16))
  kind = Bool.pick(U32, has(panels(y), x), 1, Bool.pick(U32, has(glass(y), x), 2, ...))
  Bool.pick(U32, inside, kind, 1)
```

The map drawing now lives in a comment, because it is the level design. A small program printed `cell(x, y)` for all 18x18 positions from -1 to 16 (a step left from `x = 0` wraps to a huge `U32`), and the grid matched the old map exactly.

| 720p, no bang | before | after |
|---|---|---|
| `bench` | 2.60 ms | 2.27 ms (-13%) |
| `bench_mouth` | 3.05 ms | 2.58 ms (-15%) |
| `bench_close` | 12.00 ms | 11.08 ms (-8%) |

### 2.2 Typed `pick` and `word` (rejected)

`SHADERS.md` says the generic `Bool.pick` boxes its words and recommends typed versions:

```python
def pick(c: Bool, a: F32, b: F32) -> F32:
  match c:
    case True{}:
      a
    case False{}:
      b
```

We replaced every `Bool.pick(F32, ...)` and `Bool.pick(U32, ...)` in the game. Physics and pixels stayed identical. The time did not:

| `bench_close`, 720p, 3 interleaved pairs | ms per frame |
|---|---|
| generic `Bool.pick` | 11.25, 11.18, 11.06 |
| typed `pick` / `word` | 12.88, 12.66, 12.55 |

**~13% slower.** In the emitted C, the typed version has 36 more `spin_N` calls and 31 more `if`s, and the same number of `term_keep` and `rfc_seal` (9 and 146). On the CPU, the generic pick compiles to less code. We reverted it. The guide's numbers come from the device, so this may still hold on a GPU.

### 2.3 A direct port to the 16-px tile renderer (rejected)

The spike in [GPU.md](GPU.md) is fast because its pixel is cheap: compare y with the wall's top and bottom. We tried the same tree on the real game, reusing `Col.at` (8 column chains per tile) and `View.leaf` (one colour per 2x2 block). The pixels matched all 13 snapshots.

| 720p, no bang | current renderer | direct tile port |
|---|---|---|
| `bench` | 2.24 ms | 5.48 ms (2.4x slower) |
| `bench_mouth` | 2.62 ms | 9.27 ms (3.5x slower) |
| `bench_close` | 11.10 ms | 9.91 ms (11% faster) |

Two reasons:

- **The columns run 45 times.** A tile casts its own 8 column pairs, so each column is cast once per row of tiles (720 / 16 = 45). The spike's DDA is cheap enough to not care. Our `Col.at` follows portals, clips the body and its clone, and builds a `Seen` chain.
- **Every block pays the shader.** The current renderer asks a column summary "is this block uniform?" and answers one `Pix` for big blocks of wall, floor or ring. The tile port shades every 2x2 block, and our `Shade.at` walks the portal chain with ellipse math.

The current architecture (cast each column once, summarize, compress) is already the right shape for this game. The guide's lessons had to go INTO it, not replace it.

### 2.4 The discovery: the render ran on one thread

Before trying the fork rules, we checked how the current renderer scales:

| `bench_close`, 720p, no bang | 1 thread | 4 threads | 16 threads |
|---|---|---|---|
| ms per frame | 11.20 | 11.19 | 11.36 |

**No scaling at all.** The renderer is full of parallel lets (`Cols.build` forks per column pair, `View.build` forks per `Qua`), and none of them reached the pool. Then we wrapped the same frame in one bang per frame, with an `IO.now()` between frames, exactly like `bend3d.bend`:

```python
def frame(+t: F32) -> Image:
  View.frame!(6.2, 2.5, (t * 0.001 : F32), 360.0, 0.5, 0.0, (t * 0.09 : F32), ..., 1280, 720)
```

| `bench_close`, 720p, `--gpu off` | 1 thread | 4 threads | 16 threads |
|---|---|---|---|
| no bang | 11.20 | 11.19 | 11.36 |
| one bang per frame | 13.49 | **6.51** | 8.13 |

So `!` is not only "run this on the GPU". With `--gpu off`, it is **how a program reaches the CPU pool at all**, at least from a frame loop like ours. The game now does the same: `Game.view` is a pure def that returns `(state, image)` with `View.of!(...)` inside, and `Screen.sync` is the `IO` step between the physics and the bang. `play.sh` runs `./portal --gpu off --threads 4`.

### 2.5 A bang alone is not enough

With the bang, every fork in the old renderer became a real task. The old renderer forks at every `Qua` down to 2x2 blocks, which is the guide's "a fork per pixel drowns in scheduling":

| 720p, one bang per frame, old fork shape | ms per frame | vs. no bang |
|---|---|---|
| `bench` | 4.41 | 1.7x slower |
| `bench_mouth` | 4.79 | 1.6x slower |
| `bench_close` | 11.68 | about the same |

### 2.6 Forks only down to 16 px (kept)

The fix follows the guide: fork down to 16-px blocks, then build in sequence. Both trees got a sequential twin with the same logic:

```python
# BEFORE: a parallel let at every level, down to 2x2 blocks
def build(+depth: Nat, uni: Bool, ...) -> Image:
  ...
      tl tr = build(d, ...) build(d, ...)
      bl br = build(d, ...) build(d, ...)
      Qua{tl, tr, bl, br}

# AFTER: build forks while blocks are bigger than 16 px, flat_build does the rest in sequence
def flat_build(+depth: Nat, uni: Bool, ...) -> Image:
  ...
      tl = flat_build(d, ...)
      tr = flat_build(d, ...)
      bl = flat_build(d, ...)
      br = flat_build(d, ...)
      Qua{tl, tr, bl, br}

def build(+depth: Nat, tiny: Bool, uni: Bool, ...) -> Image:
  match depth tiny uni cols:
    case _ True{} _ _:
      flat_build(depth, uni, ...)
    ...
      +tiny_next = U32.is_le(half, 16)
      tl tr = build(d, tiny_next, ...) build(d, tiny_next, ...)
```

`Cols.build` got the same split: it forks down to strips of 8 column pairs (16 px).

| `bench_close`, 720p, 4 threads | no bang | one bang per frame |
|---|---|---|
| fork at every `Qua` | 11.15 ms | 11.6 ms |
| fork down to 16 px | 11.89 ms | **6.6-7.1 ms** |

Without the bang, the cut costs 7% (the forks were free because they never forked). With the bang, it is the difference between no gain and 1.7x.

### 2.7 Dropping the last frame (left as is)

`SHADERS.md` drops the last frame inside the fork tree (`Image.open` into `Four`), because a host drop "costs milliseconds". We measured our frame first:

| `bench_close`, 720p, one bang per frame | ms per frame |
|---|---|
| drop on the host (`Image.drop`) | 6.58, 6.75 |
| drop in its own bang (`Image.drop!`, what `portal.bend` does) | 6.61, 7.05 |
| no drop at all (leaks, for reference) | 7.31, 7.21 |

The drop is lost in the noise. Our frames are small after compression (tens of thousands of leaves), so threading the old image through the tree is not worth the code.

---

## 3. The final numbers

`tests/bench.sh 2 4`: 4 scenes, 3 window sizes, mean of 2 runs, 4 threads, ms per frame.

- **A**: the last commit, as the game ran it (no bang).
- **B**: the last commit with one bang per frame (old fork shape).
- **C**: this change (bit-mask map, forks down to 16 px, one bang per frame).

| Scene | Size | A (before) | B (bang only) | **C (after)** | C vs A |
|---|---|---|---|---|---|
| `bench` | 1280x720 | 2.64 | 4.41 | **2.10** | 1.26x |
| | 1920x1080 | 5.32 | 6.73 | **3.25** | 1.64x |
| | 2560x1440 | 7.86 | 9.59 | **5.22** | 1.51x |
| `bench_noportal` | 1280x720 | 2.32 | 4.20 | **1.88** | 1.23x |
| | 1920x1080 | 4.75 | 6.31 | **3.03** | 1.57x |
| | 2560x1440 | 6.99 | 8.38 | **4.74** | 1.47x |
| `bench_mouth` | 1280x720 | 3.14 | 4.79 | **2.10** | 1.50x |
| | 1920x1080 | 5.30 | 6.66 | **3.16** | 1.68x |
| | 2560x1440 | 8.40 | 7.84 | **5.03** | 1.67x |
| `bench_close` | 1280x720 | 12.01 | 11.68 | **7.10** | 1.69x |
| | 1920x1080 | 24.95 | 22.58 | **14.32** | 1.74x |
| | 2560x1440 | 44.21 | 33.74 | **23.22** | 1.90x |

```text
  worst case (bench_close), ms per frame         60 FPS = 16.7 ms  ┆
  720p   before ████████████ 12.0                                  ┆
         after  ███████ 7.1                                        ┆
  1080p  before █████████████████████████ 25.0                     ┆
         after  ██████████████ 14.3                                ┆
  1440p  before ████████████████████████████████████████████ 44.2  ┆
         after  ███████████████████████ 23.2                       ┆
```

---

## 4. Thread scaling

After the change, with one bang per frame:

| Threads | `bench_close` 2560x1440 | `bench` 1280x720 |
|---|---|---|
| 1 | 47.6 ms | 3.47 ms |
| 2 | 29.5 ms | |
| 4 | 23.6 ms | 1.93 ms |
| 8 | 22.6 ms | 1.96 ms |
| 16 | 24.3 ms | |

It scales ~2x and flattens at 4-8 threads. `--threads 4` stays the right default for `play.sh`.

---

## 5. What is still slow

The worst case at 1440p (23 ms) is still above 60 FPS. Our leads, in order:

1. **The body turns off compression for its whole column.** `Sum.of_col` clears the summary when the body shows in a column (`clear = not front_figure`), so those columns shade every 2x2 block, from the ceiling to the floor. The body covers maybe a third of that height. A summary that knows the body's rows would keep the rest compressed.
2. **Load imbalance.** The guide says a task goes to a core once and never moves. In `bench_close` the heavy work (the portal and the body) sits in a few strips of the screen, and the scaling curve flattens at 4-8 threads. Splitting heavy regions deeper, or ordering the forks so heavy strips start first, may help.
3. **The columns under the portal build a `Seen` chain per column** (up to 8 nodes, each with a `Bodies` pair). A flatter column record would cut allocation.

---

## 6. New nitpicks

Found while doing this. They add to the list in [GPU.md](GPU.md#7-nitpicks-and-papercuts).

1. **Parallel lets outside a bang run on one thread, silently.** Nothing warns you: the program is correct, `--threads 16` is accepted, and the time does not move. We only found it by timing 1, 4 and 16 threads side by side. A line in the guide ("outside a bang, a parallel let does not reach the pool") would have saved us a lot of "Bend is single threaded for us".
2. **`!` means two things.** The guide introduces it as "runs on the GPU". With `--gpu off` it is also the only way we found to use the CPU pool. The name makes the second use easy to miss.
3. **Termination reads the arguments left to right.** `def build(tiny: Bool, +depth: Nat, ...)` is refused ("expected a decreasing self-call"), even though `depth` shrinks on every call, because `tiny` comes first and changes. Moving `depth` to the front fixes it. The error message says "arguments are read left to right", which is fair, but the rule is easy to trip on when you add a flag.
4. **A `match` on several values wants them in parameter order.** In `def build(+depth: Nat, tiny: Bool, ...)`, `match tiny depth:` fails with "a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)". `match depth tiny:` compiles. The message points to the wrong cause.
5. **The typed `pick` advice does not carry over to the CPU** (section 2.2). It may be right on the device, but the guide gives it as a general rule.

---

## 7. New questions for the Bend team

1. **Parallel lets and the pool.** Is it expected that parallel lets outside a bang run on one thread? What exactly decides whether a fork reaches the pool: only a bang, or also some shape of the root (like the `fid_nofk` flag on `U32.show` roots)?
2. **Typed pick on the CPU.** Why does `pick(c, a: F32, b: F32)` with a `match` produce more code and run 13% slower on the CPU than the generic `Bool.pick`? Is the generic one special-cased?
3. **Scaling past 4 threads.** Our worst case goes 47.6 → 29.5 → 23.6 → 22.6 ms for 1, 2, 4 and 8 threads. Is that the "a task never moves" imbalance, or pool overhead? Is work stealing planned, and until then, what is the best way to balance a frame where one region is 10x heavier than the rest?
4. **Sequential twins.** We had to copy `build` into `flat_build` to stop forking below 16 px. Is there a way to say "run this parallel let in sequence below depth k" without a second copy of the def?

---

## 8. Reproduce it

```bash
tests/bench.sh 2 4        # 4 scenes x 3 sizes, 2 runs, 4 threads (column C)
bend tests/physics.bend   # compare with the output of the last commit
bend tests/snapshot.bend | python3 tests/snapshot.py snaps
```

For columns A and B, check out the commit before this change (`git worktree add ../base <commit>`):

- **A**: build the old `tests/bench*.bend` files and time them with `--threads 4`.
- **B**: copy the new `tests/bench*.bend` and `tests/bench.sh` into the old tree and run `tests/bench.sh 2 4` there.

---

Same conclusion as the GPU report, from the other side: in Bend, **the shape of the code decides where it runs and how fast.** The guide's rules are real, but measure each one on your own workload before you keep it. From the community, to the community.
