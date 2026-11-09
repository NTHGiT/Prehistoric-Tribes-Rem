# Prehistoric Tribes: Remastered (LÖVE)

Rebuild game J2ME *Prehistoric Tribes* (THQ Wireless, 2008) dengan LÖVE 11.x.
Peta dan tekstur sekarang memakai data asli, bukan rumput polos lagi.

## Menjalankan

```bash
love .            # desktop (LÖVE 11.5)
```

Android: zip isi repo ini (`main.lua` harus di root zip) lalu ganti nama menjadi `.love`
dan buka dengan aplikasi LÖVE, atau bangun APK dengan `love-android`.

## Struktur

```
core/    simulasi murni (tanpa love.graphics): GameState, Simulation, NPCBrain, Building, Pathfinding, MapDecoder, Events
game/    render, kamera, input, UI (Renderer, TextureBank, Camera, Input, ui/*)
assets/  data hasil ekstraksi dari jar asli + hasil bake (atlas/, data/*.lua, maps/*.bin)
tools/   extract_assets.py, pack_levels.py, bake_tiles.py, lua_check.py, lua_format.py (rapikan indentasi)
docs/    ASSET_PIPELINE.md (format tile asli), preview_level00.png
```

Aturan arsitektur: `core/` tidak boleh `require` apa pun dari `game/`. Pesan ke pemain lewat `Events.notify`
(ditampilkan `game/ui/Toast.lua`).

## Mengganti level

Ubah `LEVEL` di `main.lua` (0–11). Metadata ada di `assets/data/levels.lua`.

## Perubahan dari versi sebelumnya

**Penyebab "rumput hijau polos"**
- `TextureBank` memotong gambar jadi kotak 22×16 padahal tile asli adalah daftar potongan sprite, dan
  file `pi0/04, 06, 07, 08, 11` sudah dipindah ke `assets/sprites/` sehingga `pi0/08.png` tidak ditemukan
  dan jatuh ke warna hijau cadangan. Kini file dikembalikan ke `assets/images/pi0/` dan tile di-bake
  menjadi atlas (lihat `docs/ASSET_PIPELINE.md`).

**Perbaikan bug**
- `game/Map.lua` (menggunakan `lib.json` yang tidak ada, duplikat `MapDecoder`) dan `core/PdTables.lua`
  (tebakan format yang salah) dihapus.
- Dapat dilewati atau tidak kini mengikuti aturan loader asli, bukan tebakan id tile (id 6 dulu dianggap pohon,
  padahal itu air).
- Sumber daya kini berasal dari peta, bukan 5 koordinat yang ditulis tangan; posisi gudang, dapur, dan warga
  dicari di tanah yang benar-benar bisa dilewati.
- Geser dengan mouse di PC tidak berfungsi (`love.touch.getTouches()` kosong untuk mouse). Kini pointer dilacak
  sendiri sehingga geser dan cubit berfungsi untuk sentuhan maupun mouse.
- `Input.touchpressed` dipanggil dua kali per sentuhan; dibersihkan.
- Zoom kini berpusat pada titik jari/kursor dan kamera dibatasi di dalam peta.
- Pesan dialog (`SelectionPanel.setDialog`) tidak pernah digambar; diganti `Toast`.
- A* memakai binary heap (sebelumnya `table.sort` tiap iterasi) dan batas ekspansi.
- Ketuk pohon/batu memilih node terdekat, bukan node pertama dalam daftar.
- `conf.lua`: tidak lagi fullscreen di desktop; modul tak terpakai dimatikan.
- Indentasi seluruh file Lua dirapikan (`tools/lua_format.py`, hanya spasi; `Simulation.lua` dari 42 KB menjadi 15 KB).

## Belum diuji

Saya tidak bisa menjalankan LÖVE di lingkungan ini. Yang sudah diuji: sintaks semua file Lua, logika `core/` secara headless
(4.000 tick di peta asli, panen kayu sampai habis, A*), dan rendering atlas (hasil identik piksel-demi-piksel dengan render langsung
dari tabel asli, serta culling kamera pada 60 posisi acak). Kode `game/` (Renderer, TextureBank, input sentuh) perlu dicoba di perangkat.
