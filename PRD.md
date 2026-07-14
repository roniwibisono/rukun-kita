# PRD — Rukun Kita (RT Digital Administration App)

> Dokumen ini adalah **instruksi pengembangan untuk AI coding agent** (Claude Code / Cursor / dsb). Backend Supabase **sudah live dan production-ready** — jangan mendesain ulang skema database. Gunakan skema, enum, RLS, function, dan trigger yang sudah ter-deploy sebagai kontrak data yang mengikat. Tugas AI agent adalah membangun **aplikasi Flutter** di atas backend ini.

---

## 0. Identitas Proyek

| Item | Nilai |
|---|---|
| Nama aplikasi | **Rukun Kita** (nama final, menggantikan nama kerja sebelumnya "SapaRT") |
| Tagline | "Administrasi RT, jadi lebih rukun & mudah" |
| Bundle ID / Package name | `id.skyalley.rtapps` |
| Platform target | iOS, Android, Web (satu codebase Flutter) |
| Backend | Supabase (project ref: `pgvyhgvqwhiqhfvwxata`) |
| Project URL | `https://pgvyhgvqwhiqhfvwxata.supabase.co` |
| Model bisnis | Single-tenant per RT saat ini, dengan fondasi multi-tenant (`tenants`, `tenant_memberships`, `SUPER_ADMIN`) sudah disiapkan di DB untuk ekspansi SaaS multi-RT di masa depan |

**Kredensial client (aman untuk di-embed di app karena diproteksi RLS — JANGAN pernah taruh `service_role` key di client):**

```
SUPABASE_URL=https://pgvyhgvqwhiqhfvwxata.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBndnloZ3Zxd2hpcWhmdnd4YXRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5MDMxNDksImV4cCI6MjA5OTQ3OTE0OX0.tZ8OJPrYgI2ULJxRDS0Zqa1Irq1QOEaVS676f-OZex0
SUPABASE_PUBLISHABLE_KEY=sb_publishable_UyZcElmC2-CvAIe8rybYvA_EyiFz7Yu
```

**AI agent instruction:** simpan nilai di atas di `.env` (di-`.gitignore`), load lewat `flutter_dotenv` atau `--dart-define-from-file=env.json`. Jangan hardcode di source file yang di-commit ke repo publik walau secara teknis aman.

---

## 1. Ringkasan Produk

Rukun Kita adalah aplikasi pembukuan & persuratan digital untuk pengurus RT (Rukun Tetangga) di Jakarta. Dua peran utama:

- **Warga**: mengajukan surat pengantar, melihat status permintaan, mengunduh/mengambil berkas yang sudah selesai, melihat notifikasi.
- **Admin (pengurus RT)**: memproses permintaan surat, mengelola 6 kategori buku administrasi RT, mencatat retribusi/iuran (IPL), mengelola data warga per KK dengan struktur kepala-keluarga → anggota keluarga.
- **Super Admin** (fondasi sudah ada di DB via `tenants`/`is_super_admin()`): mengelola multi-RT di masa depan — **tidak perlu dibangun di MVP**, cukup pastikan arsitektur app tidak menutup jalan ke sana (routing role sudah generic).

---

## 2. Arsitektur Sistem

### 2.1 High-level architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter Client                        │
│  (iOS / Android / Web — single codebase)                  │
│                                                             │
│  Presentation → Riverpod Providers → Repository Layer      │
│                                          │                  │
└──────────────────────────────────────────┼─────────────────┘
                                            │ supabase_flutter SDK
                                            ▼
┌─────────────────────────────────────────────────────────┐
│                Supabase (BaaS, sudah live)                 │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌────────────┐│
│  │ PostgREST │ │  Auth     │ │ Realtime  │ │  Storage   ││
│  │ (RLS-     │ │ (auth.    │ │ (postgres_│ │  (berkas / ││
│  │ enforced) │ │  users)   │ │ changes)  │ │  ttd)      ││
│  └───────────┘ └───────────┘ └───────────┘ └────────────┘│
│                     PostgreSQL 17                          │
└─────────────────────────────────────────────────────────┘
```

Prinsip arsitektur:
- **Tanpa backend custom** — semua business rule ditegakkan di Postgres via RLS policy + `security definer` functions (`is_admin()`, `current_user_role()`, `current_user_nomor_kk()`, dst). Flutter app **tidak boleh** mengandalkan validasi role di client saja — itu hanya untuk UX (hide/show menu), keamanan sesungguhnya ada di RLS.
- **Realtime-first** untuk status tiket & notifikasi (tabel `ticket_requests` dan `app_notifications` sudah masuk `supabase_realtime` publication).
- **Offline-tolerant, bukan offline-first**: cache ringan di memory/local (Hive/Isar opsional untuk read-cache), tapi semua write harus online (RT admin bekerja di kantor dengan koneksi stabil; warga hanya submit request).

### 2.2 Component structure (Flutter)

```
lib/
├── main.dart
├── app.dart                     # MaterialApp, router, theme
├── core/
│   ├── config/                  # env loader, supabase client singleton
│   ├── router/                  # go_router + role-based redirect guards
│   ├── theme/
│   ├── constants/                # enum status, jenis surat, dsb (mirror DB enum)
│   └── utils/                    # formatters (tanggal, rupiah), validators
├── data/
│   ├── models/                   # 1 file per tabel (freezed + json_serializable)
│   ├── repositories/              # 1 repo per domain (auth, warga, ticket, iuran, buku_*)
│   └── datasources/
│       └── supabase_datasource.dart
├── features/
│   ├── splash/
│   ├── auth/                      # login username + kode akses
│   ├── warga/
│   │   ├── home/
│   │   ├── ajukan_surat/
│   │   ├── riwayat_permintaan/
│   │   ├── buku_administrasi/     # read-only view + ambil berkas (date picker)
│   │   └── notifikasi/
│   ├── admin/
│   │   ├── home/
│   │   ├── permintaan_surat/      # kanban/status management
│   │   ├── retribusi_iuran/
│   │   ├── data_warga/            # expandable KK → anggota keluarga
│   │   └── buku_administrasi/     # CRUD 6 kategori
│   └── shared_widgets/
└── l10n/                          # id (default), en (opsional)
```

### 2.3 Data flow (contoh: pengajuan surat)

1. Warga isi form di `ajukan_surat` → `TicketRepository.create()` → INSERT ke `ticket_requests` (RLS: `tickets_insert_related_warga`, hanya bisa insert untuk `warga_id` miliknya/KK-nya).
2. Trigger tidak diperlukan untuk notifikasi masuk ke admin — **AI agent perlu menambahkan** Edge Function atau client-side insert ke `app_notifications` dengan target admin (lihat §7.3 untuk gap yang perlu diisi).
3. Admin membuka `permintaan_surat`, subscribe Realtime channel `ticket_requests` (filter `status`), update status via `TicketRepository.updateStatus()`.
4. Saat status berubah ke `SELESAI`, sistem insert row ke `app_notifications` untuk `warga_id` terkait → warga menerima push/local notif via Realtime subscription + (opsional) FCM.
5. Warga menekan "Ambil Berkas" → pilih tanggal di date picker → update `pickup_date` → status berubah ke `COMPLETE` saat admin konfirmasi fisik di kantor RT.

---

## 3. Tech Stack Flutter

| Layer | Pilihan | Alasan |
|---|---|---|
| State management | **Riverpod (hooks_riverpod + riverpod_generator)** | Testable, cocok untuk async data dari Supabase, tidak perlu BuildContext |
| Routing | **go_router** | Deep-linking role-based redirect (splash → login → home sesuai role), cocok untuk web juga |
| Backend SDK | **supabase_flutter** | Official SDK, auth + postgrest + realtime + storage jadi satu |
| Model/serialization | **freezed + json_serializable** | Immutable model, mapping 1:1 ke kolom tabel |
| Local cache (opsional) | **Hive** | Cache ringan untuk data referensi (daftar jenis surat, dsb), bukan source of truth |
| Form | **flutter_form_builder** | Form dinamis untuk 6+ jenis surat & 12+ buku administrasi |
| Date picker | bawaan Material `showDatePicker` | Kebutuhan "ambil berkas" |
| Notifikasi lokal | **flutter_local_notifications** | Trigger dari Realtime event |
| Push (opsional fase 2) | **firebase_messaging** | Saat app di-background/killed |
| Charts (retribusi) | **fl_chart** | Ringkasan IPL bulanan |
| i18n | **flutter_localizations + intl** | Default Bahasa Indonesia |

---

## 4. Auth Flow — Penting (Gap Desain yang Harus Diputuskan AI Agent)

Skema DB (`profiles.username`) mengasumsikan login **username + kode akses**, sementara Supabase Auth native bekerja dengan **email/phone + password**. Karena `auth.users` sudah dipakai (trigger `handle_new_user_profile` jalan `after insert on auth.users`), gunakan pendekatan berikut agar konsisten dengan DB yang sudah ada:

**Pendekatan yang direkomendasikan: Pseudo-email mapping**
- Saat signup/provisioning warga oleh admin: buat akun Supabase Auth dengan email sintetis `"{username}@rukunkita.internal"` dan password = kode akses.
- Layar login Flutter hanya menampilkan 2 field: **Username** dan **Kode Akses** (sesuai wireframe user). Di balik layar, `AuthRepository.login(username, kodeAkses)` melakukan:
  ```dart
  supabase.auth.signInWithPassword(
    email: '$username@rukunkita.internal',
    password: kodeAkses,
  );
  ```
- Admin membuat akun warga baru via halaman admin → memanggil Supabase Admin API (butuh Edge Function dengan `service_role`, **jangan** panggil dari client) yang generate username unik + kode akses awal (bisa di-reset warga).

**AI agent instruction:** buat 1 Edge Function `create-warga-account` (Deno) yang dipanggil admin untuk provisioning akun, karena `service_role` tidak boleh ada di Flutter app.

---

## 5. Alur Layar (User Flow)

```
Splash Screen
  → load: session check, remote config ringan (versi app min, jenis surat list)
  → jika session valid → redirect sesuai role
  → jika tidak → Login Screen

Login Screen
  → teks sambutan + field Username + field Kode Akses + tombol Masuk
  → sukses → cek profiles.role →
      WARGA        → Warga Home
      ADMIN        → Admin Home
      SUPER_ADMIN  → Super Admin Home (stub/fase depan)
```

### 5.1 Warga Home — Menu

1. **Ajukan Surat** → pilih jenis (KTP baru/hilang, KK, Akta Lahir/Wafat, Numpang Nikah, SKTM, Domisili, Pindah) → isi detail → submit → masuk `ticket_requests`.
2. **Riwayat Permintaan Saya** → list status (BARU/DIPROSES/SELESAI/PENDING/COMPLETE/BATAL) dengan realtime badge, tombol **Batalkan** (hanya jika status `BARU`/`DIPROSES` dan `pickup_date is null`, sesuai constraint RLS `tickets_update_related_cancel_or_admin`).
3. **Buku Administrasi (read-only, sesuai KK sendiri)** — tab per kategori (lihat §6), setiap baris relevan punya kolom **Ambil Berkas** dengan date picker.
4. **Notifikasi** → list `app_notifications` milik warga/KK, realtime, mark-as-read.
5. **Profil Saya / Keluarga** → tampilkan `warga_induk` milik sendiri + anggota keluarga lain dengan `nomor_kk` sama (read-only).

### 5.2 Admin Home — Menu

1. **Permintaan Surat** — daftar semua tiket, filter by status, badge notifikasi baru masuk. Aksi ubah status sesuai state machine (§6.1). Detail tiket menampilkan data pemohon (join ke `warga_induk`).
2. **Retribusi / Iuran Bulanan (IPL)** — tabel `iuran_ipl` per tahun, filter warga **aktif/non-aktif** (`warga_induk.is_active`), checklist bulan yang sudah dibayar (`bulan_bayar int[]`), auto-hitung `total_bayar`.
3. **Data Warga** — tabel `warga_induk` dikelompokkan per KK. Baris kepala keluarga (root, `parent_id is null` **atau** row pertama per `nomor_kk`) bisa di-*expand* menampilkan anggota keluarga lain dengan `nomor_kk` sama. CRUD penuh (create/update/delete sesuai grant `admin_all`).

   > Catatan struktur data: kolom `parent_id` di `warga_induk` mereferensikan diri sendiri, tapi grouping utama sebaiknya berbasis `nomor_kk` (lebih robust untuk keluarga tanpa parent eksplisit). AI agent: implementasikan grouping di query/repository layer dengan `GROUP BY nomor_kk`, bukan mengandalkan `parent_id` semata.

4. **Buku Administrasi** — 6 kategori penuh CRUD:
   - Kependudukan: `warga_induk` (Buku Induk), `warga_mutasi`, `warga_sementara`
   - Persuratan: `surat_masuk`, `surat_keluar`, `buku_ekspedisi`, (Surat Pengantar Warga = view dari `ticket_requests`)
   - Keuangan: `kas_umum`, `iuran_ipl`
   - Rapat: `notulen_rapat`, `presensi_rapat`
   - Pengawasan: `buku_tamu`, `inventaris_rt`
   - Internal Pengurus: `pengurus_rt`

---

## 6. State Machine — Ticket Status

```
BARU ──(admin proses)──▶ DIPROSES ──(berkas siap)──▶ SELESAI ──(warga ambil, admin konfirmasi)──▶ COMPLETE
  │                          │                            │
  │                          │                     (lewat X hari, belum diambil)
  └──(warga batal)──▶ BATAL  └──(warga batal)──▶ BATAL     └──▶ PENDING ──(akhirnya diambil)──▶ COMPLETE
```

Aturan implementasi:
- Transisi ke `SELESAI` → trigger insert `app_notifications` (`type = 'TICKET_SELESAI'`) untuk `warga_id` terkait — **realtime push ke warga**.
- `SELESAI` → `PENDING` sebaiknya dijalankan oleh **scheduled Edge Function** (pg_cron / Supabase Cron) yang cek `ticket_requests` dengan status `SELESAI` dan `updated_at` lebih lama dari N hari (buat N dikonfigurasi, default 7 hari) — bukan logic di client, karena warga bisa saja tidak pernah membuka app.
- `BATAL` hanya bisa dilakukan warga jika `pickup_date is null` (sudah ditegakkan oleh RLS check, cukup mirror validasi ini di UI supaya tombol batal disable dengan tepat).

---

## 7. Data Model → Flutter Mapping

Gunakan 1 model per tabel, field wajib mirror 1:1 nama & tipe kolom (snake_case di DB → camelCase di Dart via `@JsonKey`). Contoh:

```dart
@freezed
class WargaInduk with _$WargaInduk {
  const factory WargaInduk({
    required String id,
    String? profileId,
    String? parentId,
    required String namaLengkap,
    required String nomorKk,
    required String nik,
    String? jenisKelamin,
    String? tempatLahir,
    required DateTime tanggalLahir,
    String? agama,
    String? pendidikan,
    String? pekerjaan,
    String? statusPernikahan,
    String? hubunganKeluarga,
    required String alamatLengkap,
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _WargaInduk;

  factory WargaInduk.fromJson(Map<String, dynamic> json) => _$WargaInukFromJson(json);
}
```

Ulangi pola ini untuk: `Profile`, `WargaMutasi`, `WargaSementara`, `TicketRequest`, `AppNotification`, `SuratMasuk`, `SuratKeluar`, `BukuEkspedisi`, `KasUmum`, `IuranIpl`, `BukuTamu`, `InventarisRt`, `NotulenRapat`, `PresensiRapat`, `PengurusRt`, `Tenant`, `TenantMembership`.

Enum mirror dari DB:
```dart
enum UserRole { warga, admin, superAdmin }
enum TicketStatus { baru, diproses, selesai, complete, pending, batal }
enum MutasiType { lahir, meninggal, pindahMasuk, pindahKeluar }
enum KondisiBarang { baik, rusak }
```

---

## 8. Caching Strategy

| Data | Strategi |
|---|---|
| Session/JWT | Persisted otomatis oleh `supabase_flutter` (secure storage) |
| Daftar jenis surat, referensi statis | Hardcode/config lokal, tidak perlu query DB |
| `ticket_requests` (warga & admin) | Realtime subscription, in-memory Riverpod state, **tidak** disimpan ke disk (data berubah cepat) |
| `warga_induk` per KK | Cache read 5 menit (Riverpod `AsyncValue` + `ref.invalidate` manual refresh), karena jarang berubah |
| `app_notifications` | Realtime subscription + local unread counter di Riverpod |
| Laporan/agregat (retribusi bulanan, kas) | Query on-demand, tidak di-cache lintas sesi (butuh data terbaru saat admin buka laporan) |

Tidak direkomendasikan pakai cache HTTP layer tambahan (Supabase PostgREST sudah efisien untuk skala 1 RT/~ratusan KK; over-engineering caching di MVP tidak perlu).

---

## 9. Keamanan (ringkasan yang sudah ditegakkan di DB — jangan diduplikasi validasinya secara longgar di client)

- RLS aktif di semua tabel domain.
- `is_admin()`, `is_super_admin()`, `current_user_nomor_kk()` adalah `security definer` function — dipakai berulang di policy, jangan reimplement logic role di client sebagai source of truth.
- Warga hanya bisa lihat/insert data terkait `nomor_kk`/`profile_id` miliknya.
- Admin (`ADMIN`/`SUPER_ADMIN`) punya akses penuh ke seluruh tabel operasional RT.
- `service_role` key **tidak boleh** ada di Flutter app — hanya dipakai di Edge Function untuk provisioning akun & cron job status.

---

## 10. Fase Pengembangan (untuk AI agent, kerjakan berurutan)

1. **Fase 0 — Setup**: init Flutter project (`id.skyalley.rtapps`), setup `supabase_flutter`, `.env`, `go_router` skeleton, generate semua model dari skema di atas.
2. **Fase 1 — Auth & Splash**: splash screen, login username+kode akses (pseudo-email mapping), role-based redirect.
3. **Fase 2 — Modul Warga**: ajukan surat, riwayat status (realtime), buku administrasi read-only + ambil berkas date picker, notifikasi.
4. **Fase 3 — Modul Admin**: permintaan surat (state machine + realtime), data warga (expandable KK), retribusi/IPL, 6 kategori buku administrasi (CRUD).
5. **Fase 4 — Notifikasi & Automation**: Edge Function cron untuk `SELESAI → PENDING`, Edge Function `create-warga-account`, local notification trigger dari Realtime event.
6. **Fase 5 — Polish & Release**: theming, empty/error states, form validation lengkap, testing (widget + integration terhadap Supabase test project), build iOS/Android/Web, submission checklist.

---

## 11. Non-Functional Requirements

- Bahasa default UI: Indonesia.
- Skala target awal: 1 RT (~50–300 KK) — desain tidak perlu horizontal scaling agresif, tapi jangan blokir jalur ke multi-tenant (`tenants` sudah ada).
- Semua timestamp disimpan UTC di DB, ditampilkan dalam waktu lokal (WIB) di UI.
- Semua form input yang match kolom NIK/KK harus divalidasi format (16 digit) di client sebelum submit, sebagai UX improvement — bukan pengganti validasi server.
