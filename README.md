# Rukun Kita — Flutter Skeleton

Skeleton project ini adalah starting point untuk pengembangan lanjutan sesuai `PRD.md`. Backend Supabase **sudah live** (lihat kredensial di `.env.example`) — skeleton ini sudah dikabelkan (wired) langsung ke skema tabel yang sudah ada.

## Yang sudah tersedia

- ✅ Struktur folder lengkap (`core`, `data`, `features`) sesuai PRD §2.2
- ✅ 17 model data (1:1 mirror ke tabel Supabase) — `lib/data/models/`
- ✅ Repository layer untuk semua domain (auth, warga, ticket, notifikasi, iuran, 10 buku administrasi) — `lib/data/repositories/`
- ✅ Enum yang mirror tipe enum Postgres (`user_role`, `ticket_status`, `mutasi_type`, `kondisi_barang`)
- ✅ Riverpod provider wiring (`repository_providers.dart`)
- ✅ Router dasar (`go_router`) dengan redirect berbasis role
- ✅ Splash → Login (username + kode akses) → Home (Warga/Admin) — bisa langsung dijalankan
- ✅ `.env.example` sudah berisi kredensial Supabase project ini
- ✅ Platform scaffold Android/Web dengan package `id.skyalley.rtapps`
- ✅ Modul Warga MVP:
  - Ajukan surat
  - Riwayat permintaan realtime
  - Buku administrasi read-only keluarga/surat
  - Notifikasi + mark-as-read
  - Profil keluarga
- ✅ Modul Admin MVP:
  - Permintaan surat realtime + state machine
  - Data warga grouped per `nomor_kk`
  - Retribusi/IPL per tahun + update bulan bayar
  - Buku administrasi CRUD generik berbasis JSON untuk semua tabel buku

## Yang BELUM dibuat (langkah selanjutnya untuk AI agent/developer)

Mengikuti Fase di PRD §10:

1. **Edge Function `create-warga-account`** — provisioning akun warga oleh admin (butuh `service_role`, tidak boleh di client). Lihat PRD §4.
2. **Edge Function cron** untuk transisi otomatis `SELESAI → PENDING` setelah N hari.
3. Form khusus per buku administrasi. Saat ini admin sudah bisa CRUD lewat editor JSON generik; berikutnya pecah menjadi form domain-friendly per tabel.
4. Logo & asset brand di `assets/images/` (splash screen masih pakai placeholder `FlutterLogo`).
5. Local notification trigger dari Realtime stream (`flutter_local_notifications` sudah ada di `pubspec.yaml`, belum di-wire).
6. Test lebih luas untuk flow auth, ticket, dan repository terhadap Supabase test project.

## Cara menjalankan

```bash
# 1. Install Flutter SDK (>=3.3.0) jika belum ada
flutter --version

# 2. Copy env
cp .env.example .env

# 3. Install dependencies
flutter pub get

# 4. Jalankan
flutter run                 # pilih device Android/Chrome
flutter run -d chrome        # khusus web
```

> Catatan: model di project ini ditulis manual (bukan `freezed`) supaya bisa langsung jalan tanpa `build_runner`. Jika ingin migrasi ke `freezed` untuk immutability + `copyWith` otomatis, jalankan:
> ```bash
> dart run build_runner build --delete-conflicting-outputs
> ```
> setelah menambahkan anotasi `@freezed` di tiap model.

## Struktur folder

```
lib/
├── main.dart                  # entry point
├── app.dart                   # MaterialApp.router
├── core/
│   ├── config/                # env.dart, supabase_client_provider.dart
│   ├── router/                # app_router.dart (go_router + role redirect)
│   ├── theme/                 # app_theme.dart
│   └── constants/              # enums.dart, table_names.dart
├── data/
│   ├── models/                 # 17 model, 1:1 mirror tabel Supabase
│   ├── repositories/           # repository per domain + repository_providers.dart
│   └── datasources/            # supabase_datasource.dart (base class)
└── features/
    ├── splash/, auth/
    ├── warga/{home,ajukan_surat,riwayat_permintaan,buku_administrasi,notifikasi}/
    └── admin/{home,permintaan_surat,retribusi_iuran,data_warga,buku_administrasi}/
```

Referensi lengkap arsitektur & keputusan desain ada di `PRD.md` (root project ini, disertakan sebagai referensi).
