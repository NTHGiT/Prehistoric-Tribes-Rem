# Pipeline aset

Game asli menyimpan sebuah tile bukan sebagai satu gambar, tetapi sebagai **daftar potongan sprite**.
Itu sebabnya memotong `pi0/08.png` jadi kotak 22×16 tidak pernah berhasil (hasilnya rumput hijau atau abu-abu).
Format aslinya (semua diverifikasi, lihat `docs/BLUEPRINT.md` bagian 4.3):

```
tile id ──► short_9[id]        bit 0-12 : indeks awal di short_10
                               bit 14-15: jenis bayangan (0 = tanpa)
            byte_16[id] & 63   : jumlah potongan
potongan i ► short_10[i]       bit 0-12 : id sprite (atau id tile lain bila bit 13 = 1 → bersarang)
                               bit 14-15: tambahan offset x (×128)
            byte_18[i], byte_19[i] : offset x, y (signed)
sprite s ──► byte_20[s] & 31   : nomor gambar pi0 (0..26)
            byte_21[s] & 127   : sumber x     byte_22[s] : sumber y
            byte_23[s]         : lebar        byte_24[s] : tinggi

tile id >= 175 adalah OBJEK statis (pohon, ilalang, tulang, ...):
object o = id - 146 ──► short_0[o] = indeks awal di short_1, byte_0[o] = jumlah entri
entri n ► short_1[n] & 4095 = id tile, byte_1/byte_2[n] = offset x/y,
          byte_3[n] >> 6 = layer (layer <= tahap yang digambar; peta statis memakai tahap 0)
```

`tools/bake_tiles.py` menjalankan daftar itu sekali saat build dan menulis satu atlas
(`assets/atlas/terrain.png` + `assets/data/terrain_atlas.lua`), jadi di Lua satu sel peta = satu quad.

## Perintah

```bash
pip install pillow
python3 tools/pack_levels.py     # assets/maps/level_NN.json -> level_NN.bin + data/levels.lua
python3 tools/bake_tiles.py      # tabel pd0 + gambar pi0     -> atlas/terrain.png + data/terrain_atlas.lua + data/tile_info.lua
python3 tools/lua_check.py $(git ls-files '*.lua')   # cek sintaks Lua (butuh liblua5.4)
```

`tools/extract_assets.py` membongkar jar asli (butuh folder jar yang sudah di-unzip) dan menghasilkan
JSON peta, tabel, PNG, MIDI, dan teks yang menjadi bahan dua skrip di atas.

## Aturan gameplay yang diambil dari kode asli (`f.aN`)

| Aturan | Sumber |
|---|---|
| Sel tidak bisa dilewati bila `tile >= 175` atau bit 13 `short_9[tile]` aktif | `tile_info.lua` → `blocked` |
| Baris pertama, baris terakhir, dan kolom terakhir peta selalu solid | `MapDecoder.load` |
| Level 0 hanya bisa dimainkan di area 40×32; level 5 kehilangan 32 kolom kanan | `levels.lua` → `playWidth/playHeight` |
| Tile 175–179 adalah sumber makanan/tulang dengan jumlah 20, 20, 20, 15, 25 | `MapDecoder` (`SPAWN`) |
| Posisi awal kursor tiap level | `levels.lua` → `startX/startY` |

## Yang BUKAN data asli (aturan prototipe)

- Kayu dari pohon (tile 180–229) dan batu dari tebing/bongkahan (41–62, 63–75, 115–127), beserta jumlahnya.
  Game asli memanen keduanya dengan cara lain; ini hanya supaya seni peta bisa dipakai.
- Arti tiap jenis sumber (BUSH, FISH, BONE) ditebak dari gambar tile-nya.
- Bangunan dan warga masih kotak dan lingkaran; sprite aslinya belum didekode (tugas T3 berikutnya:
  tabel `short_0..4` / `byte_0..3` untuk unit, `f.java` baris 1521–1760).
