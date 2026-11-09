#!/usr/bin/env python3
"""Bake the original J2ME composite tiles into one texture atlas for LOVE.

The original game never stores a tile as one picture. A tile/object is a short list of
sprite pieces (docs/BLUEPRINT.md, section 4.3). This script replays that list once, at
build time, so the Lua runtime only has to draw one quad per cell.

Reads : assets/data/pd0_tables.json, assets/images/pi0/NN.png, assets/maps/level_*.json
Writes: assets/atlas/terrain.png, assets/data/terrain_atlas.lua, assets/data/tile_info.lua

usage : python3 tools/bake_tiles.py [assets_dir]        (needs Pillow)
"""
import glob, hashlib, json, os, sys
from PIL import Image

A = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets')
T = json.load(open(f'{A}/data/pd0_tables.json'))
u16 = lambda a: [v & 0xFFFF for v in a]
b0, b1, b9, b10 = (u16(T[f'short_{i}']) for i in (0, 1, 9, 10))
J = {i: T[f'byte_{i}'] for i in (0, 1, 2, 3, 16, 18, 19, 20, 21, 22, 23, 24)}

imgs = {}
for i in range(27):
    for d in ('images/pi0', 'sprites'):
        p = f'{A}/{d}/{i:02d}.png'
        if os.path.exists(p):
            imgs[i] = Image.open(p).convert('RGBA'); break
if len(imgs) != 27: sys.exit(f'missing pi0 images: {sorted(set(range(27)) - set(imgs))}')

OX, OY, SZ = 96, 160, 320      # where the 22x16 cell sits inside the scratch canvas

def sprite(cv, sid, x, y):
    if sid == 0: return
    k = J[20][sid] & 31
    if k >= 27: return                                   # 27..30 = vector primitives, not used by terrain
    sx, sy, w, h = J[21][sid] & 127, J[22][sid] & 255, J[23][sid] & 255, J[24][sid] & 255
    if w and h and 0 <= x and 0 <= y and x + w <= SZ and y + h <= SZ:
        cv.alpha_composite(imgs[k].crop((sx, sy, sx + w, sy + h)), (x, y))

def tile(cv, t, x, y, depth=0):
    """Composite tile: sprite pieces (table short_9 -> short_10), pieces may nest other tiles."""
    if depth > 4 or t >= len(b9): return
    e = b9[t]; start = e & 8191; shadow = (e >> 14) & 3
    if shadow: sprite(cv, (shadow - 1) * 3 + 1, x, y)
    for i in range(start, start + (J[16][t] & 63)):
        p = b10[i]; sid = p & 8191; xo = ((p & 0xC000) >> 14) << 7
        if p & 8192: tile(cv, sid, x + J[18][i] + xo, y + J[19][i], depth + 1)
        else:        sprite(cv, sid, x + J[18][i] + xo, y + J[19][i])

def obj(cv, oid, stage=0):
    """Object = list of tiles, each with a layer (bits 6-7 of byte_3); layers <= stage are drawn."""
    for n in range(b0[oid], b0[oid] + (J[0][oid] & 255)):
        if ((J[3][n] & 255) >> 6) <= stage:
            tile(cv, b1[n] & 4095, OX + J[1][n], OY + J[2][n])

# which map tile ids does the game really use?
used = set()
for f in glob.glob(f'{A}/maps/level_*.json'):
    for row in json.load(open(f))['tiles']: used.update(row)
used = sorted(t for t in used if t <= 255 and (t < 175 or t - 146 < len(b0)))

jobs = {}                                                # name -> function(canvas)
def ground_job(t):
    def run(cv):
        if t < 175: return tile(cv, t, OX, OY)           # plain ground tile
        top = Image.new('RGBA', (SZ, SZ), (0, 0, 0, 0))  # >= 175: static object (trees, reeds, bones ...)
        obj(top, t - 146)
        if top.crop((OX, OY, OX + 22, OY + 16)).getchannel('A').getextrema()[0] < 255:
            tile(cv, 0, OX, OY)                          # art with holes (e.g. bones): lay grass underneath
        cv.alpha_composite(top)
    return run
for t in used:
    jobs[f'g{t}'] = ground_job(t)

pieces, cells = {}, {}                                   # md5 -> (image, offX, offY) / name -> md5
for name, fn in jobs.items():
    cv = Image.new('RGBA', (SZ, SZ), (0, 0, 0, 0)); fn(cv)
    bb = cv.getbbox()
    if not bb: continue
    crop = cv.crop(bb)
    h = hashlib.md5(crop.tobytes() + repr((crop.size, bb[0] - OX, bb[1] - OY)).encode()).hexdigest()
    pieces.setdefault(h, (crop, bb[0] - OX, bb[1] - OY)); cells[name] = h

W, GUTTER = 1024, 2                                      # shelf packing
order = sorted(pieces, key=lambda h: -pieces[h][0].height)
x = y = rowh = 0; pos = {}
for h in order:
    w, hh = pieces[h][0].size
    if x + w + GUTTER > W: x, y, rowh = 0, y + rowh + GUTTER, 0
    pos[h] = (x, y); x += w + GUTTER; rowh = max(rowh, hh)
atlas = Image.new('RGBA', (W, y + rowh + GUTTER), (0, 0, 0, 0))
for h in order: atlas.paste(pieces[h][0], pos[h])
os.makedirs(f'{A}/atlas', exist_ok=True); atlas.save(f'{A}/atlas/terrain.png', optimize=True)

def entry(name):
    h = cells[name]; im, ox, oy = pieces[h]
    return '{%d,%d,%d,%d,%d,%d}' % (*pos[h], im.width, im.height, ox, oy)

ground_ids = [t for t in used if f'g{t}' in cells]
reach = lambda t: (-pieces[cells[f'g{t}']][1], -pieces[cells[f'g{t}']][2],
                   pieces[cells[f'g{t}']][1] + pieces[cells[f'g{t}']][0].width - 22,
                   pieces[cells[f'g{t}']][2] + pieces[cells[f'g{t}']][0].height - 16)
ov = [max(0, max(reach(t)[i] for t in ground_ids)) for i in range(4)]
with open(f'{A}/data/terrain_atlas.lua', 'w') as f:
    f.write('-- GENERATED by tools/bake_tiles.py - do not edit.\n')
    f.write('-- entry = {x, y, w, h, offsetX, offsetY}; offset is relative to the top-left of the 22x16 cell.\n')
    f.write('return {\n  width = %d, height = %d, tileW = 22, tileH = 16,\n' % atlas.size)
    f.write('  -- how many pixels map art reaches outside its own cell: left, up, right, down\n')
    f.write('  overhang = {%d, %d, %d, %d},\n  ground = {\n' % tuple(ov))
    for t in ground_ids: f.write('    [%d] = %s,\n' % (t, entry(f'g{t}')))
    f.write('  },\n}\n')

with open(f'{A}/data/tile_info.lua', 'w') as f:                # same rules as the original loader (f.aN)
    f.write('-- GENERATED by tools/bake_tiles.py - do not edit.\n')
    f.write('-- blocked : tile >= 175 or bit 13 of short_9        (original marks the cell -126)\n')
    f.write('-- special : (byte_16 >> 6) & 3 == 2                  (original marks the cell -125)\n')
    f.write('-- solid   : 180..231                                 (original marks the cell -124)\n')
    f.write('-- resource: 175..179 spawn a harvestable object, type = tile - 174 (original: f.aN)\nreturn {\n')
    f.write('  blocked = {%s},\n' % ','.join(str(t) for t in range(256) if t >= 175 or (t < len(b9) and b9[t] & 8192)))
    f.write('  special = {%s},\n}\n' % ','.join(str(t) for t in range(256) if t < len(b9) and (J[16][t] >> 6) & 3 == 2))
print('atlas', atlas.size, '| unique pieces', len(pieces), '| cells', len(cells), '| overhang', ov)
