#!/usr/bin/env bash
# Run the render benchmarks at three window sizes, as the game runs them.
# Usage: tests/bench.sh [runs] [threads]
set -euo pipefail
cd "$(dirname "$0")/.."
runs=${1:-2}
threads=${2:-4}
out=tests/build
rm -rf "$out" && mkdir -p "$out"
for scene in bench bench_noportal bench_mouth bench_close; do
  for size in 1280x720 1920x1080 2560x1440; do
    w=${size%x*}
    h=${size#*x}
    hor=$(awk -v h="$h" 'BEGIN { printf "%.1f", h / 2 }')
    sed -e "s/1280, 720)/$w, $h)/" -e "s/360\.0/$hor/g" "tests/$scene.bend" > "tests/${scene}_$size.bend"
    bend "tests/${scene}_$size.bend" -o "$out/${scene}_$size" > /dev/null
    rm "tests/${scene}_$size.bend"
  done
done
for i in $(seq "$runs"); do
  for scene in bench bench_noportal bench_mouth bench_close; do
    for size in 1280x720 1920x1080 2560x1440; do
      ms=$("$out/${scene}_$size" --gpu off --threads "$threads" | awk '{ print $2 }')
      awk -v s="$scene" -v z="$size" -v m="$ms" 'BEGIN { printf "%-15s %-10s %6.2f ms/frame\n", s, z, m / 300 }'
    done
  done
done
