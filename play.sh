#!/usr/bin/env bash
# Few threads: the frame is small, and to wake 32 workers costs more than the render.
cd "$(dirname "$0")"
changed_source=$(find portal.bend game \( -name '*.bend' -o -name '*.c' \) -newer portal 2>/dev/null | head -1)
[ -x portal ] && [ -z "$changed_source" ] || bend portal.bend -o portal
exec ./portal --threads 4
