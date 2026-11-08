#!/usr/bin/env python3
import colorsys, json, os, sys

def h2r(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) / 255 for i in (0, 2, 4))

def r2h(c):
    return '#%02x%02x%02x' % tuple(max(0, min(255, round(x * 255))) for x in c)

def mix(a, b, t):
    A, B = h2r(a), h2r(b)
    return r2h(tuple(x + (y - x) * t for x, y in zip(A, B)))

def hsl(h):
    hh, l, s = colorsys.rgb_to_hls(*h2r(h))
    return hh * 360, s, l

def pick(target, pool, fallback, tol=35):
    best = None
    for c in pool:
        h, s, _ = hsl(c)
        if s < 0.15:
            continue
        d = abs(h - target)
        d = min(d, 360 - d)
        if d <= tol and (best is None or d < best[0]):
            best = (d, c)
    return best[1] if best else fallback

home = os.path.expanduser('~')
src = json.load(open(f'{home}/.cache/iris/colors.json'))
out = sys.argv[1] if len(sys.argv) > 1 else f'{home}/.cache/iris/wallpaper-theme.json'

dark = bool(src.get('dark', True))
bg, surface, fg, dim, accent = src['bg'], src['surface'], src['fg'], src['dim'], src['accent']
skip = {'bg', 'surface', 'fg', 'dim'}
pool = [v for k, v in src.items() if isinstance(v, str) and v.startswith('#') and k not in skip]

colors = {
    'bg_dim': mix(bg, '#000000', 0.25 if dark else 0.06),
    'bg0': bg,
    'bg1': surface,
    'bg2': mix(surface, dim, 0.35),
    'bg3': mix(surface, dim, 0.70),
    'bg4': dim,
    'primary_container': mix(bg, accent, 0.22),
    'secondary_container': mix(bg, pick(50, pool, '#dbbc7f'), 0.22),
    'foreground': fg,
    'muted': mix(fg, bg, 0.35),
    'muted_dark': mix(fg, bg, 0.55),
    'red': pick(0, pool, '#e67e80'),
    'orange': pick(25, pool, '#e69875'),
    'yellow': pick(50, pool, '#dbbc7f'),
    'green': pick(120, pool, '#a7c080'),
    'aqua': pick(165, pool, '#83c092'),
    'blue': pick(210, pool, '#7fbbb3'),
    'purple': pick(275, pool, '#d699b6'),
    'primary': accent,
}

ah, ahs, _ = hsl(accent)
folders = [(15, 'red'), (40, 'orange'), (70, 'yellow'), (165, 'green'), (195, 'teal'),
           (255, 'blue'), (285, 'violet'), (330, 'magenta'), (345, 'pink')]
fc = 'bluegrey' if ahs < 0.2 else next((n for lim, n in folders if ah < lim), 'red')
apps = {'neovim': 'everforest', 'alacritty': 'wallpaper', 'folder_color': fc}

json.dump({'name': 'Wallpaper', 'slug': 'wallpaper',
           'appearance': 'dark' if dark else 'light',
           'colors': colors, 'applications': apps}, open(out, 'w'), indent=2)
print('wrote', out)
