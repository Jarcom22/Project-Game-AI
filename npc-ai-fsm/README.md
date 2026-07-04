# AI Maze - Labirin Acak dengan Musuh FSM (Patroli & Kejar)

Proyek Godot 4. Setiap kali dijalankan, labirinnya digenerate ulang secara
acak (procedural), lengkap dengan kunci, pintu keluar, dan satu musuh yang
gerak sendiri pakai Finite State Machine: patroli dulu, baru ngejar kalau
pemain benar-benar kelihatan (dicek pakai raycast, bukan cuma jarak lurus,
soalnya di labirin banyak tembok yang menghalangi pandangan).

## Cara menjalankan

1. Buka Godot Engine 4.3 (atau versi 4.x terbaru).
2. Klik **Import**, arahkan ke folder `npc-ai-fsm`, lalu pilih `project.godot`.
3. Tekan tombol Run (F5). Scene utama: `scenes/Main.tscn`.
4. Kontrol: tombol panah (kanan/kiri/atas/bawah) buat gerakin si pemain (kotak biru).
5. Ambil kunci (ikon biru) dulu, baru boleh masuk ke kotak merah (exit) buat menang.
6. Kalau kesentuh musuh (muka kuning marah), kalah, labirin baru langsung dibikin ulang.

## Struktur proyek

```
npc-ai-fsm/
├── project.godot
├── icon.svg
├── scenes/
│   ├── Main.tscn        # scene utama, cuma wadah kosong + UI, isinya dibangun lewat kode
│   ├── Player.tscn       # pemain (wireframe biru)
│   ├── Enemy.tscn         # musuh + FSM (wireframe muka kuning)
│   ├── Key.tscn            # kunci
│   └── Goal.tscn            # kotak tujuan (merah, ada X)
└── scripts/
    ├── MazeGenerator.gd      # generator labirin (recursive backtracker) + BFS
    ├── Player.gd              # gerak 4 arah, deteksi kunci/goal/musuh
    ├── Enemy.gd                # INI AI-NYA: FSM patrol -> chase -> return
    ├── Key.gd                   # penanda grup "key"
    ├── Goal.gd                   # penanda grup "goal"
    └── Main.gd                    # generate labirin, naruh entitas, atur menang/kalah
```

## Cara kerja labirinnya

`MazeGenerator.gd` bikin labirin baru tiap game dimulai, pakai algoritma
**recursive backtracker** (randomized depth-first search): mulai dari satu
sel, terus gali dinding ke sel tetangga yang belum dikunjungi secara acak,
mundur (backtrack) kalau jalan buntu, sampai semua sel kebagian jalan.
Hasilnya labirin yang selalu bisa diselesaikan dan bentuknya beda tiap kali
main.

Posisi kunci, exit, dan titik awal musuh dihitung otomatis pakai BFS
(breadth-first search) di atas labirin yang sudah jadi:
- **Exit** = sel yang paling jauh dari titik start (biar jalannya panjang).
- **Kunci** = sel yang jaraknya kira-kira di tengah antara start dan exit.
- **Musuh** = mulai dari sel lain, lalu jalan-jalan acak menyusuri koridor
  asli sepanjang beberapa langkah, itu jadi rute patrolinya.

## Cara kerja FSM pada musuh (Enemy.gd)

| State  | Perilaku                                                                |
|--------|--------------------------------------------------------------------------|
| PATROL | Mondar-mandir di rute koridor yang sudah dihitung Main.gd                |
| CHASE  | Ngejar pemain langsung, aktif kalau pemain masuk `detection_radius` DAN benar-benar kelihatan (raycast ke tembok tidak terhalang) |
| RETURN | Balik ke titik patroli terakhir kalau pemain kabur lebih jauh dari `give_up_radius` atau ketutup tembok, baru lanjut PATROL lagi |

Status state musuh ditampilkan langsung di atas kepalanya buat debugging/demo.

## Parameter yang bisa diubah lewat Inspector

Node **Main**: `cols`, `rows` (ukuran labirin), `cell_size`, `margin`.
Node **Enemy** (lewat scene Enemy.tscn): `speed`, `chase_speed`, `detection_radius`, `give_up_radius`.
Node **Player**: `speed`.
