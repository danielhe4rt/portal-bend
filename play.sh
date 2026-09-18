#!/usr/bin/env bash
# Few threads: the frame is small, and to wake 32 workers costs more than the render.
# --gpu off: on a discrete GPU the bang is slower than the CPU pool (docs/guide/GPU.md).
cd "$(dirname "$0")"
changed_source=$(find portal.bend game \( -name '*.bend' -o -name '*.c' \) -newer portal 2>/dev/null | head -1)
[ -x portal ] && [ -z "$changed_source" ] || bend portal.bend -o portal
exec ./portal --gpu off --threads 4
