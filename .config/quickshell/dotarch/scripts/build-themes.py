#!/usr/bin/env python3
"""Cluster wallpapers by colour and build one theme per cluster using iris."""
import argparse, colorsys, json, os, shutil, subprocess, sys
import numpy as np
from PIL import Image

HOME = os.path.expanduser('~')
WALL = f'{HOME}/Pictures/Wallpapers'
THEMES = f'{HOME}/.config/vyeos/themes'
STATE = f'{HOME}/.local/state/vyeos'
IRIS = f'{HOME}/.local/bin/iris'
CONV = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'iris-to-theme.py')
EXT = ('.jpg', '.jpeg', '.png', '.webp', '.gif')

ap = argparse.ArgumentParser()
ap.add_argument('--themes', type=int, default=None, help='aim for about this many themes (picks the match threshold for you)')
ap.add_argument('--match', type=float, default=0.15, help='how close a wallpaper must be to the wallpaper its theme is built from (smaller = more, tighter themes)')
ap.add_argument('--min', type=int, default=6, help='smallest allowed theme (smaller ones are merged)')
ap.add_argument('--dry-run', action='store_true')
ap.add_argument('--max', type=int, default=45, help='split any theme larger than this into finer themes')
ap.add_argument('--sweep', action='store_true', help='show theme counts for several match values and exit')
ap.add_argument('--clean', action='store_true', help='remove old theme folders and generated themes first')
args = ap.parse_args()

def features(path):
    im = Image.open(path)
    if im.format == 'JPEG':
        im.draft('RGB', (128, 128))
    try:
        im.seek(0)
    except Exception:
        pass
    im = im.convert('RGB')
    im.thumbnail((64, 64))
    rgb = np.asarray(im, dtype=np.float32) / 255
    hsv = np.asarray(im.convert('HSV'), dtype=np.float32) / 255
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    w = s * v
    ang = h * 2 * np.pi
    hx, hy = float((w * np.cos(ang)).mean()), float((w * np.sin(ang)).mean())
    lum = float((0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]).mean())
    return [hx * 4, hy * 4, lum]

def kmeans(X, k, seed=7, iters=80):
    rng = np.random.default_rng(seed)
    cent = [X[rng.integers(len(X))]]
    for _ in range(1, k):
        d = np.min(((X[:, None, :] - np.array(cent)[None]) ** 2).sum(-1), axis=1)
        cent.append(X[rng.choice(len(X), p=d / d.sum())] if d.sum() > 0 else X[rng.integers(len(X))])
    cent = np.array(cent)
    for _ in range(iters):
        lab = ((X[:, None, :] - cent[None]) ** 2).sum(-1).argmin(1)
        new = np.array([X[lab == i].mean(0) if (lab == i).any() else cent[i] for i in range(k)])
        if np.allclose(new, cent):
            break
        cent = new
    lab = ((X[:, None, :] - cent[None]) ** 2).sum(-1).argmin(1)
    return lab, cent

def merge_small(X, lab, cent, min_size):
    while True:
        ids = [i for i in range(len(cent)) if (lab == i).any()]
        sizes = {i: int((lab == i).sum()) for i in ids}
        small = [i for i in ids if sizes[i] < min_size]
        if not small or len(ids) == 1:
            return lab, cent
        i = min(small, key=lambda j: sizes[j])
        others = [j for j in ids if j != i]
        idx = np.where(lab == i)[0]
        d = ((X[idx][:, None, :] - cent[others][None]) ** 2).sum(-1)
        lab[idx] = np.array(others)[d.argmin(1)]
        for j in others:
            cent[j] = X[lab == j].mean(0)

def rgb01(h):
    return tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))

HUES = [(15, 'Crimson'), (40, 'Amber'), (65, 'Gold'), (95, 'Olive'), (165, 'Moss'), (195, 'Teal'),
        (225, 'Azure'), (255, 'Indigo'), (285, 'Violet'), (320, 'Orchid'), (345, 'Rose')]

def name_for(theme, used):
    c = theme['colors']
    h, _, s = colorsys.rgb_to_hls(*rgb01(c['primary']))
    bgl = colorsys.rgb_to_hls(*rgb01(c['bg0']))[1]
    hue = 'Slate' if s < 0.2 else next((n for lim, n in HUES if h * 360 < lim), 'Crimson')
    tone = 'Daylight' if theme['appearance'] == 'light' else ('Midnight' if bgl < 0.10 else 'Dusk')
    base, n = f'{tone} {hue}', 1
    name = base
    while name in used:
        n += 1
        name = f'{base} {n}'
    used.add(name)
    return name

def make_theme(rep):
    subprocess.run([IRIS, rep], check=True, capture_output=True)
    tmp = '/tmp/iris-theme.json'
    subprocess.run([sys.executable, CONV, tmp], check=True, capture_output=True)
    return json.load(open(tmp))

def clean():
    for f in os.listdir(THEMES):
        p = f'{THEMES}/{f}'
        if f == 'wallpaper.json':
            os.remove(p)
        elif f.endswith('.json'):
            try:
                if json.load(open(p)).get('generated'):
                    os.remove(p)
            except Exception:
                pass
    subdirs = [d for d in os.listdir(WALL) if os.path.isdir(f'{WALL}/{d}')]
    top = {f for f in os.listdir(WALL) if os.path.isfile(f'{WALL}/{f}')}
    missing = [f'{d}/{f}' for d in subdirs for f in os.listdir(f'{WALL}/{d}') if f not in top]
    if missing:
        sys.exit('ABORT: files exist only in theme folders:\n' + '\n'.join(missing))
    for d in subdirs:
        shutil.rmtree(f'{WALL}/{d}')
        print('removed folder', d)

files = sorted(f for f in os.listdir(WALL) if f.lower().endswith(EXT) and os.path.isfile(f'{WALL}/{f}'))
subdirs = [d for d in os.listdir(WALL) if os.path.isdir(f'{WALL}/{d}')]
if subdirs and not args.dry_run and not args.clean:
    sys.exit('Theme folders already exist (' + ', '.join(subdirs[:4]) + ' ...). Re-run with --clean.')
if args.clean and not args.dry_run:
    os.makedirs(THEMES, exist_ok=True)
    clean()

print(f'reading {len(files)} wallpapers...')
names, feats = [], []
for n, f in enumerate(files, 1):
    try:
        feats.append(features(f'{WALL}/{f}'))
        names.append(f)
    except Exception as e:
        print('  skipped', f, e)
    if n % 100 == 0:
        print(f'  ...{n}/{len(files)}')
X = np.array(feats)
D = np.sqrt(((X[:, None, :] - X[None]) ** 2).sum(-1))

def cluster(T):
    left = set(range(len(names)))
    out = []
    while left:
        pool = np.array(sorted(left))
        sub = D[np.ix_(pool, pool)]
        m = int((sub <= T).sum(1).argmax())
        members = [int(i) for i in pool[sub[m] <= T]]
        out.append((int(pool[m]), members))
        left -= set(members)
    return out

if args.sweep:
    for t in (0.03, 0.05, 0.07, 0.09, 0.12, 0.15, 0.2, 0.25, 0.3):
        cs = cluster(t)
        sizes = sorted((len(m) for _, m in cs), reverse=True)
        print(f'match {t:<5} -> {len(cs):>3} themes, largest {sizes[0]:>3}, top 6: {sizes[:6]}')
    sys.exit(0)

if args.themes:
    lo, hi = 0.0, float(D.max()) + 1e-6
    for _ in range(30):
        mid = (lo + hi) / 2
        if len(cluster(mid)) > args.themes:
            lo = mid
        else:
            hi = mid
    T = hi
else:
    T = args.match
def split_big(cl, max_size):
    out = []
    for medoid, idx in cl:
        if len(idx) <= max_size:
            out.append((medoid, idx))
            continue
        k = int(np.ceil(len(idx) / (max_size * 0.8)))
        lab, _ = kmeans(X[idx], k)
        for g in range(k):
            members = [idx[i] for i in np.where(lab == g)[0]]
            if not members:
                continue
            sd = D[np.ix_(members, members)]
            out.append((members[int(sd.sum(1).argmin())], members))
    return out

clusters = cluster(T)
for _ in range(4):
    clusters = split_big(clusters, args.max)
clusters = sorted(clusters, key=lambda c: -len(c[1]))
print(f'match threshold {T:.3f} -> {len(clusters)} themes')

used, built = set(), []
for medoid, idx in clusters:
    order = sorted(idx, key=lambda j: D[medoid, j])
    theme = rep = None
    for j in order[:5]:
        try:
            rep = names[j]
            theme = make_theme(f'{WALL}/{rep}')
            break
        except Exception:
            continue
    if theme is None:
        print('  could not build a theme for a group of', len(idx))
        continue
    theme['name'] = name_for(theme, used)
    theme['slug'] = theme['name'].lower().replace(' ', '-')
    theme['generated'] = True
    built.append((theme, [names[j] for j in idx], rep))

print(f'\n{"theme":<22}{"wallpapers":>10}  palette source')
for theme, members, rep in built:
    print(f'{theme["name"]:<22}{len(members):>10}  {rep}   accent {theme["colors"]["primary"]}')

if args.dry_run:
    print('\ndry run: nothing written.')
    sys.exit(0)

os.makedirs(THEMES, exist_ok=True)
with open(f'{HOME}/wallpaper-themes-report.tsv', 'w') as rpt:
    for theme, members, rep in built:
        json.dump(theme, open(f'{THEMES}/{theme["slug"]}.json', 'w'), indent=2)
        d = f'{WALL}/{theme["slug"]}'
        os.makedirs(d, exist_ok=True)
        for f in members:
            dst = f'{d}/{f}'
            if not os.path.exists(dst):
                try:
                    os.link(f'{WALL}/{f}', dst)
                except OSError:
                    shutil.copy2(f'{WALL}/{f}', dst)
            rpt.write(f'{f}\t{theme["slug"]}\n')

os.makedirs(f'{STATE}/wallpapers', exist_ok=True)
open(f'{STATE}/current-theme', 'w').write(built[0][0]['slug'] + '\n')
for stale in ('wallpapers/wallpaper',):
    try:
        os.remove(f'{STATE}/{stale}')
    except OSError:
        pass
print(f'\nwrote {len(built)} themes. current theme: {built[0][0]["slug"]}')
print(f'report: {HOME}/wallpaper-themes-report.tsv')
