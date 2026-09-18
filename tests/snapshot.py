#!/usr/bin/env python3
"""Make PNGs from the output of tests/snapshot.bend: bend tests/snapshot.bend | python3 tests/snapshot.py <dir>
A scene name can include the window size: "# name@960x1000: description". The default is 1280x720."""
import sys, zlib, struct

W, H = 1280, 720

def fill(tokens, buf, x, y, size):
    tok = next(tokens)
    if tok == "Q":
        half = size // 2
        for ox, oy in ((0, 0), (half, 0), (0, half), (half, half)):
            fill(tokens, buf, x + ox, y + oy, half)
        return
    color = int(tok)
    rgb = bytes(((color >> 16) & 255, (color >> 8) & 255, color & 255))
    x1, y1 = min(x + size, W), min(y + size, H)
    if x >= W or y >= H:
        return
    row = rgb * (x1 - x)
    for yy in range(y, y1):
        buf[(yy * W + x) * 3:(yy * W + x1) * 3] = row

def png(path, buf):
    raw = b"".join(b"\x00" + bytes(buf[r * W * 3:(r + 1) * W * 3]) for r in range(H))
    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))

out = sys.argv[1] if len(sys.argv) > 1 else "."
scenes, current = [], None
for line in sys.stdin.read().split("\n"):
    if line.startswith("#"):
        current = []
        scenes.append((line[2:].split(":")[0], current))
    elif line:
        current.append(line)
sys.setrecursionlimit(10000)
for name, toks in scenes:
    _, _, size = name.partition("@")
    W, H = map(int, size.split("x")) if size else (1280, 720)
    root = 1
    while root < max(W, H):
        root *= 2
    buf = bytearray(W * H * 3)
    fill(iter(toks), buf, 0, 0, root)
    path = f"{out}/snap_{name.replace('@', '_')}.png"
    png(path, buf)
    print(f"{path}  ({len(toks)} nodes)")
