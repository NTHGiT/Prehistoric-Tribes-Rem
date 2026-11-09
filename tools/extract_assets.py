#!/usr/bin/env python3
"""Extract assets from the unpacked Prehistoric Tribes J2ME jar.
Usage: python3 extract_assets.py <unpacked_jar_dir> <out_dir>"""
import sys, os, json, struct

src, out = sys.argv[1], sys.argv[2]
rd = lambda p: open(os.path.join(src, p), 'rb').read()
def w(path, data, mode='wb'):
    path = os.path.join(out, path); os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, mode).write(data)

# splash screens (plain PNG)
for i in range(4): w(f'splash/l{i}.png', rd(f'l{i}'))

# image packs: [u16 big-endian length][PNG]; length 0 = empty slot
for name, cnt in (('pi0', 31), ('pi9', 6), ('pi8', 12)):
    d, p = rd(name), 0
    for i in range(cnt):
        n = (d[p] << 8) | d[p+1]; p += 2
        if n: w(f'images/{name}/{i:02d}.png', d[p:p+n])
        p += n

# pd0: 11 short arrays + 25 byte arrays (big-endian), sizes from e.java
sizes = [119,1291,162,162,2782,144,1069,6903,823,1721,5492,119,1291,1291,1291,162,162,162,
         2782,2782,144,1069,1069,6903,6903,6903,823,1721,42,5492,5492,1810,1810,1810,1810,1810]
d = rd('pd0'); p = 1; tables = {}
for i, n in enumerate(sizes):
    if i <= 10:
        tables[f'short_{i}'] = list(struct.unpack('>%dh' % n, d[p:p+2*n])); p += 2*n
    else:
        tables[f'byte_{i-11}'] = list(struct.unpack('%db' % n, d[p:p+n])); p += n
assert p == len(d), (p, len(d))
w('data/pd0_tables.json', json.dumps(tables), 'w')

# 'a': 312 chunks [u16 LE len][bytes] (font metrics, direction tables, ...) + 5 u16-LE short tables
d = rd('a'); p = 0; chunks = []
for i in range(312):
    n = d[p] | (d[p+1] << 8); p += 2; chunks.append(list(d[p:p+n])); p += n
groups = []
for i in range(5):
    n = d[p] | (d[p+1] << 8); p += 2
    groups.append(list(struct.unpack('<%dh' % n, d[p:p+2*n]))); p += 2*n
assert p == len(d)
w('data/a_tables.json', json.dumps({'chunks': chunks, 'short_groups': groups}), 'w')

# music: sa = 5 MIDI tracks (offsets from e.java)
sa = rd('sa'); o = [0, 8014, 14329, 19977, 23382, len(sa)]
for i in range(5): w(f'audio/music_{i}.mid', sa[o[i]:o[i+1]])

# maps: 'ma' = 10 RLE-compressed tilemap segments; 12 levels (q) pick a segment via chunk 248
# dimensions: chunk 149 = (w,h) pairs per level; chunk 197: run-length patterns (len[0..5], tile[6..11])
ma = rd('ma'); seg = [0, 2545, 6965, 10649, 15487, 22633, 27261, 31708, 35466, 39214, len(ma)]
c149, c197, c248 = chunks[149], chunks[197], chunks[248]
def decode(buf, wd, ht):
    pos = 0; cnt = 10; pid = 0; tile = 0; rows = []
    for y in range(ht):
        row = []
        for x in range(wd):
            if cnt >= c197[pid]:
                tile = buf[pos]; pos += 1
                if tile >= 250: cnt = 0; pid = tile - 250; tile = c197[6 + pid]
            cnt += 1; row.append(tile)
        rows.append(row)
    return rows, pos
for q in range(12):
    wd, ht = c149[q*2], c149[q*2+1]; si = c248[q]
    buf = ma[seg[si]:seg[si+1]]
    rows, used = decode(buf, wd, ht); assert used == len(buf), (q, used, len(buf))
    w(f'maps/level_{q:02d}.json', json.dumps({'level': q, 'width': wd, 'height': ht, 'segment': si, 'tiles': rows}), 'w')
    w(f'maps/segments/seg_{si}.bin', buf)

# text: folders 0..4 = en, fr, it, de, es ; '|' separates strings
for i, lang in enumerate(('en', 'fr', 'it', 'de', 'es')):
    for f, key in (('s', 'ui'), ('t', 'descriptions'), ('d0', 'story')):
        txt = rd(f'{i}/{f}').decode('latin-1')
        w(f'text/{lang}/{key}.json', json.dumps(txt.split('|'), ensure_ascii=False, indent=1), 'w')
print('done ->', out)
