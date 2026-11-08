#!/usr/bin/env python3
import glob, json, os, re, sys
H = os.path.expanduser('~')
T, W, S = f'{H}/.config/vyeos/themes', f'{H}/Pictures/Wallpapers', f'{H}/.local/state/vyeos'
TSV = f'{H}/wallpaper-themes-report.tsv'
MERGES = [('Dusk Amber 3', 'Dusk Crimson 2'), ('Dusk Crimson', 'Dusk Rose 2'), ('Daylight Slate 3', 'Daylight Slate 2')]
NAMES = {
 'Dusk Slate': 'Deep Space', 'Dusk Azure': 'Blueprint', 'Dusk Amber': 'Apricot Haze',
 'Dusk Slate 2': 'Sage Valley', 'Dusk Gold': 'Candlelight', 'Dusk Slate 3': 'Nightshade',
 'Dusk Slate 4': 'Lavender Skyline', 'Dusk Amber 2': 'Blue Hour', 'Dusk Azure 2': 'Cloud Drift',
 'Daylight Violet': 'Ultraviolet', 'Daylight Orchid': 'Atlantis', 'Daylight Moss': 'Watermelon',
 'Dusk Amber 3': 'Sunset Ember', 'Daylight Rose': 'Wine Blossom', 'Daylight Moss 2': 'Overgrown',
 'Dusk Rose': 'Phantom', 'Dusk Azure 3': 'Lagoon', 'Daylight Slate': 'Cotton Candy',
 'Daylight Rose 2': 'Plum Grove', 'Daylight Orchid 2': 'Custard', 'Daylight Moss 3': 'Meadow Sky',
 'Dusk Moss': 'Mint Garden', 'Dusk Crimson': 'Rosy Dawn', 'Daylight Azure 2': 'Aquamarine',
 'Daylight Azure': 'Cobalt Toast', 'Dusk Teal': 'Ice Glass', 'Dusk Rose 2': 'Peony',
 'Dusk Crimson 2': 'Salmon Sky', 'Daylight Slate 3': 'Tiger Ink', 'Daylight Slate 2': 'Steel Blush',
 'Daylight Moss 4': 'Kiwi', 'Daylight Amber': 'Bronze Hour',
}
slug = lambda n: re.sub(r'[^a-z0-9]+', '-', n.lower()).strip('-')

def load():
    out = {}
    for p in glob.glob(f'{T}/*.json'):
        d = json.load(open(p)); out[d['name']] = (p, d)
    return out

def retag_tsv(old, new):
    if not os.path.exists(TSV): return
    rows = [l.rstrip('\n').split('\t') for l in open(TSV)]
    open(TSV, 'w').write(''.join('\t'.join([r[0], new if r[1] == old else r[1]]) + '\n' for r in rows if len(r) > 1))

def fix_state(old, new, drop=False):
    cur = f'{S}/current-theme'
    if os.path.exists(cur) and open(cur).read().strip() == old:
        open(cur, 'w').write(new + '\n')
    for p in [f'{S}/current-wallpaper'] + glob.glob(f'{S}/wallpapers/*'):
        try: t = open(p).read()
        except OSError: continue
        if f'/Wallpapers/{old}/' in t:
            open(p, 'w').write(t.replace(f'/Wallpapers/{old}/', f'/Wallpapers/{new}/'))
    o = f'{S}/wallpapers/{old}'
    if os.path.exists(o):
        os.remove(o) if drop else os.rename(o, f'{S}/wallpapers/{new}')

themes = load()
if '--merge' in sys.argv:
    for keep, drop in MERGES:
        if keep not in themes or drop not in themes:
            print('skip merge (not found):', keep, '+', drop); continue
        ks, ds = themes[keep][1]['slug'], themes[drop][1]['slug']
        for f in os.listdir(f'{W}/{ds}'):
            os.replace(f'{W}/{ds}/{f}', f'{W}/{ks}/{f}')
        os.rmdir(f'{W}/{ds}'); os.remove(themes[drop][0])
        retag_tsv(ds, ks); fix_state(ds, ks, drop=True)
        print(f'merged {drop} -> {keep}')
    themes = load()

for old, new in NAMES.items():
    if old not in themes:
        print('skip rename (not found):', old); continue
    p, d = themes[old]
    o, n = d['slug'], slug(new)
    d['name'], d['slug'] = new, n
    json.dump(d, open(f'{T}/{n}.json', 'w'), indent=2)
    if p != f'{T}/{n}.json': os.remove(p)
    if o != n and os.path.isdir(f'{W}/{o}'): os.rename(f'{W}/{o}', f'{W}/{n}')
    retag_tsv(o, n); fix_state(o, n)
print('done')
