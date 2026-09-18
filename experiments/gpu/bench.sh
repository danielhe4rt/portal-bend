#!/usr/bin/env bash
# Build the GPU experiments and run the benchmark matrix of docs/guide/GPU.md.
# Output goes to experiments/gpu/build. Set CUDA_HOME if CUDA is not at /usr/local/cuda.
# Usage: experiments/gpu/bench.sh [runs]
set -euo pipefail
cd "$(dirname "$0")"
runs=${1:-2}
[ -z "${CUDA_HOME:-}" ] && [ -d /opt/cuda ] && export CUDA_HOME=/opt/cuda
rm -rf build && mkdir -p build

variant() {
  local name=$1 w=$2 h=$3 depth=$4 hor=$5 scale=$6 src=$7
  mkdir -p "build/$name"
  sed -e "s/^  1280$/  $w/" -e "s/^  720$/  $h/" -e "s/node!(7n/node!($depth/" \
      -e "s/, 360.0}/, $hor}/" -e "s/400.0 \/ d/$scale \/ d/" "$src" > "build/$name/ray.bend"
  cp after/probe.bend "build/$name/"
  (cd "build/$name" && bend probe.bend -o probe >/dev/null)
}

variant 720p   1280 720  7n 360.0  400.0  after/ray.bend
variant 1080p  1920 1080 7n 540.0  600.0  after/ray.bend
variant 2160p  3840 2160 8n 1080.0 1200.0 after/ray.bend

sed 's/  node!(7n, True{}/  node!(7n, False{}/' after/ray.bend > build/empty.bend
variant empty 1280 720 7n 360.0 400.0 build/empty.bend

python3 - <<'EOF'
s = open("after/ray.bend").read()
start, end = s.index("def tile("), s.index("def open(")
cols = " + ".join(f"at(col((x + {i} : U32), cam), y)" for i in range(0, 16, 2))
tile = f"def tile(+x: U32, +y: U32, +cam: Cam, old: Four) -> Image:\n  Pix{{({cols} : U32)}}\n\n"
open("build/noalloc.bend", "w").write(s[:start] + tile + s[end:])
EOF
variant noalloc-720p  1280 720  7n 360.0  400.0  build/noalloc.bend
variant noalloc-2160p 3840 2160 8n 1080.0 1200.0 build/noalloc.bend

for i in $(seq "$runs"); do
  for name in 720p 1080p 2160p empty noalloc-720p noalloc-2160p; do
    for mode in "--gpu 4GB" "--gpu off --threads 4" "--gpu off --threads 16"; do
      printf '%-14s %-22s %s\n' "$name" "$mode" "$(cd "build/$name" && ./probe $mode | tail -1)"
    done
  done
done
