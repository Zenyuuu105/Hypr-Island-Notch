#!/usr/bin/env python3
"""Print the path of a PNG of THEME's pointer at about SIZE px, or nothing."""
import os, re, shutil, subprocess, sys, tempfile

theme, size = sys.argv[1], int(sys.argv[2])
home = os.path.expanduser("~")
roots = [home + "/.local/share/icons", home + "/.icons", "/usr/share/icons", "/usr/local/share/icons"]
names = ["left_ptr", "default", "arrow", "top_left_arrow"]
cache = home + "/.cache/dotarch/cursor-preview"
os.makedirs(cache, exist_ok=True)
out = "%s/%s-%d.png" % (cache, re.sub(r"[^A-Za-z0-9._-]", "_", theme), size)
if os.path.exists(out):
    print(out); sys.exit(0)

def find(name, depth=0, seen=None):
    seen = seen if seen is not None else set()
    if name in seen or depth > 5: return None
    seen.add(name)
    inherits = []
    for r in roots:
        d = os.path.join(r, name)
        for n in names:
            f = os.path.join(d, "cursors", n)
            if os.path.exists(f): return f
        idx = os.path.join(d, "index.theme")
        if os.path.exists(idx):
            for line in open(idx, errors="ignore"):
                if line.lower().startswith("inherits"):
                    inherits += [x.strip() for x in line.split("=", 1)[1].split(",") if x.strip()]
    for parent in inherits:
        f = find(parent, depth + 1, seen)
        if f: return f
    return None

src = find(theme)
if not src: sys.exit(1)
tmp = tempfile.mkdtemp(prefix="curprev-")
try:
    cfg = os.path.join(tmp, "cfg")
    subprocess.run(["xcur2png", "-q", "-c", cfg, "-d", tmp, "-p", "c", src],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    best = None
    for line in open(cfg):
        if line.startswith("#") or not line.strip(): continue
        f = line.split()
        s, path = int(f[0]), f[3]
        if not os.path.isabs(path): path = os.path.join(tmp, path)
        if not os.path.exists(path): continue
        key = (s < size, abs(s - size))
        if best is None or key < best[0]: best = (key, path)
    if not best: sys.exit(1)
    shutil.copy(best[1], out)
    print(out)
finally:
    shutil.rmtree(tmp, ignore_errors=True)
