import '../../../core/constants/table_names.dart';

/// Tipe kontrol form yang dipetakan ke tipe kolom Postgres asli.
enum BookFieldType {
  text,
  multiline,
  integer,
  decimal,
  date,
  time,
  dropdownEnum,
  dropdownRef,
}

/// Satu opsi untuk field bertipe [BookFieldType.dropdownEnum].
class BookFieldOption {
  const BookFieldOption(this.value, this.label);

  /// Value asli yang dikirim ke DB (harus sama persis dengan enum Postgres).
  final String value;

  /// Label yang ditampilkan ke pengguna.
  final String label;
}

/// Deskripsi satu field form — 1 field mewakili 1 kolom di tabel Supabase.
class BookField {
  const BookField({
    required this.key,
    required this.label,
    required this.type,
    this.required = true,
    this.hint,
    this.options = const [],
    this.refTable,
  });

  /// Nama kolom persis di tabel (snake_case).
  final String key;
  final String label;
  final BookFieldType type;
  final bool required;
  final String? hint;

  /// Opsi untuk [BookFieldType.dropdownEnum].
  final List<BookFieldOption> options;

  /// Tabel referensi untuk [BookFieldType.dropdownRef]
  /// (mis. `warga_induk` untuk memilih nama warga).
  final String? refTable;
}

/// Konfigurasi field per tabel — SUMBER KEBENARAN untuk form dinamis di
/// `AdminBukuAdministrasiPage`. Kolom di sini harus mirror 1:1 dengan
/// `toInsertJson()` masing-masing model di `data/models/`.
///
/// Catatan: `warga_induk` (tab "Buku Induk") sengaja TIDAK ada di sini —
/// tabel itu dikelola lewat halaman "Data Warga" yang sudah punya validasi
/// & alur khusus (grouping per KK, klaim profil, dll), supaya tidak ada dua
/// jalur tulis yang berbeda untuk data yang sama.
final Map<String, List<BookField>> bukuAdministrasiFieldConfig = {
  TableNames.wargaMutasi: [
    const BookField(
        key: 'nama_warga', label: 'Nama warga', type: BookFieldType.text),
    const BookField(
      key: 'alamat_lama_baru',
      label: 'Alamat lama/baru',
      type: BookFieldType.multiline,
    ),
    const BookField(
      key: 'jenis_mutasi',
      label: 'Jenis mutasi',
      type: BookFieldType.dropdownEnum,
      options: [
        BookFieldOption('LAHIR', 'Lahir'),
        BookFieldOption('MENINGGAL', 'Meninggal'),
        BookFieldOption('PINDAH_MASUK', 'Pindah masuk'),
        BookFieldOption('PINDAH_KELUAR', 'Pindah keluar'),
      ],
    ),
    const BookField(
        key: 'tanggal_mutasi',
        label: 'Tanggal mutasi',
        type: BookFieldType.date),
    const BookField(
      key: 'keterangan',
      label: 'Keterangan / alasan',
      type: BookFieldType.multiline,
      required: false,
    ),
  ],
  TableNames.wargaSementara: [
    const BookField(
        key: 'nama_lengkap', label: 'Nama lengkap', type: BookFieldType.text),
    const BookField(
        key: 'nik_paspor', label: 'NIK / No. Paspor', type: BookFieldType.text),
    const BookField(
      key: 'alamat_asal',
      label: 'Alamat asal',
      type: BookFieldType.multiline,
      required: false,
    ),
    const BookField(
        key: 'pekerjaan',
        label: 'Pekerjaan',
        type: BookFieldType.text,
        required: false),
    const BookField(
      key: 'penanggung_jawab',
      label: 'Penanggung jawab (pemilik kos/kontrakan)',
      type: BookFieldType.text,
      required: false,
    ),
    const BookField(
      key: 'tanggal_mulai',
      label: 'Tanggal mulai menetap',
      type: BookFieldType.date,
    ),
    const BookField(
      key: 'tanggal_keluar',
      label: 'Tanggal keluar',
      type: BookFieldType.date,
      required: false,
    ),
  ],
  TableNames.suratMasuk: [
    const BookField(
        key: 'tanggal_terima',
        label: 'Tanggal terima',
        type: BookFieldType.date),
    const BookField(
        key: 'nomor_surat', label: 'Nomor surat', type: BookFieldType.text),
    const BookField(
        key: 'tanggal_surat', label: 'Tanggal surat', type: BookFieldType.date),
    const BookField(
        key: 'perihal', label: 'Perihal', type: BookFieldType.multiline),
    const BookField(
        key: 'nama_pengirim', label: 'Nama pengirim', type: BookFieldType.text),
    const BookField(
      key: 'disposisi_ketua',
      label: 'Disposisi ketua RT',
      type: BookFieldType.multiline,
      required: false,
    ),
  ],
  TableNames.suratKeluar: [
    const BookField(
        key: 'tanggal_keluar',
        label: 'Tanggal keluar',
        type: BookFieldType.date),
    const BookField(
      key: 'alamat_tujuan',
      label: 'Alamat tujuan surat',
      type: BookFieldType.multiline,
    ),
    const BookField(
        key: 'perihal', label: 'Perihal', type: BookFieldType.multiline),
    const BookField(
      key: 'nama_penandatangan',
      label: 'Nama penandatangan',
      type: BookFieldType.text,
    ),
    const BookField(
      key: 'keterangan',
      label: 'Keterangan',
      type: BookFieldType.multiline,
      required: false,
    ),
  ],
  TableNames.bukuEkspedisi: [
    const BookField(
        key: 'tanggal_kirim', label: 'Tanggal kirim', type: BookFieldType.date),
    const BookField(
        key: 'nomor_surat', label: 'Nomor surat', type: BookFieldType.text),
    const BookField(
        key: 'perihal', label: 'Perihal', type: BookFieldType.multiline),
    const BookField(
        key: 'nama_penerima', label: 'Nama penerima', type: BookFieldType.text),
    const BookField(
      key: 'tanda_tangan_url',
      label: 'URL tanda tangan (opsional)',
      type: BookFieldType.text,
      required: false,
    ),
  ],
  TableNames.kasUmum: [
    const BookField(
        key: 'tanggal_transaksi',
        label: 'Tanggal transaksi',
        type: BookFieldType.date),
    const BookField(
        key: 'uraian',
        label: 'Uraian transaksi',
        type: BookFieldType.multiline),
    const BookField(
      key: 'nomor_bukti',
      label: 'Nomor bukti / kwitansi',
      type: BookFieldType.text,
      required: false,
    ),
    const BookField(
      key: 'debet',
      label: 'Debet (uang masuk)',
      type: BookFieldType.decimal,
      required: false,
      hint: 'Kosongkan jika 0',
    ),
    const BookField(
      key: 'kredit',
      label: 'Kredit (uang keluar)',
      type: BookFieldType.decimal,
      required: false,
      hint: 'Kosongkan jika 0',
    ),
    const BookField(
        key: 'saldo_akhir', label: 'Saldo akhir', type: BookFieldType.decimal),
  ],
  TableNames.bukuTamu: [
    const BookField(
        key: 'tanggal_datang',
        label: 'Tanggal datang',
        type: BookFieldType.date),
    const BookField(
        key: 'nama_tamu', label: 'Nama lengkap tamu', type: BookFieldType.text),
    const BookField(
        key: 'alamat_asal',
        label: 'Alamat asal',
        type: BookFieldType.multiline),
    const BookField(
      key: 'tamu_ke_warga_id',
      label: 'Bertamu ke rumah (warga)',
      type: BookFieldType.dropdownRef,
      refTable: TableNames.wargaInduk,
    ),
    const BookField(
        key: 'hubungan',
        label: 'Hubungan',
        type: BookFieldType.text,
        required: false),
    const BookField(
        key: 'keperluan',
        label: 'Keperluan berkunjung',
        type: BookFieldType.multiline),
    const BookField(
      key: 'tanggal_pulang',
      label: 'Tanggal kepulangan',
      type: BookFieldType.date,
      required: false,
    ),
  ],
  TableNames.inventarisRt: [
    const BookField(
        key: 'nama_barang', label: 'Nama barang', type: BookFieldType.text),
    const BookField(
      key: 'merek_tipe',
      label: 'Merek / tipe',
      type: BookFieldType.text,
      required: false,
    ),
    const BookField(
        key: 'jumlah', label: 'Jumlah (unit)', type: BookFieldType.integer),
    const BookField(
      key: 'tanggal_perolehan',
      label: 'Tanggal perolehan',
      type: BookFieldType.date,
      required: false,
    ),
    const BookField(
      key: 'asal_barang',
      label: 'Asal barang (beli/hibah)',
      type: BookFieldType.text,
      required: false,
    ),
    const BookField(
      key: 'kondisi',
      label: 'Kondisi barang',
      type: BookFieldType.dropdownEnum,
      options: [
        BookFieldOption('BAIK', 'Baik'),
        BookFieldOption('RUSAK', 'Rusak'),
      ],
    ),
  ],
  TableNames.notulenRapat: [
    const BookField(
        key: 'tanggal_rapat', label: 'Tanggal rapat', type: BookFieldType.date),
    const BookField(
        key: 'waktu_rapat', label: 'Waktu rapat', type: BookFieldType.time),
    const BookField(
        key: 'tempat_rapat', label: 'Tempat rapat', type: BookFieldType.text),
    const BookField(
        key: 'agenda', label: 'Agenda rapat', type: BookFieldType.multiline),
    const BookField(
      key: 'pembahasan',
      label: 'Jalannya pembahasan / diskusi',
      type: BookFieldType.multiline,
    ),
    const BookField(
      key: 'hasil_keputusan',
      label: 'Hasil keputusan rapat',
      type: BookFieldType.multiline,
    ),
    const BookField(
        key: 'notulis_nama', label: 'Nama notulis', type: BookFieldType.text),
  ],
  TableNames.presensiRapat: [
    const BookField(
      key: 'rapat_id',
      label: 'Rapat',
      type: BookFieldType.dropdownRef,
      refTable: TableNames.notulenRapat,
    ),
    const BookField(
      key: 'warga_id',
      label: 'Warga yang hadir',
      type: BookFieldType.dropdownRef,
      refTable: TableNames.wargaInduk,
    ),
  ],
  TableNames.pengurusRt: [
    const BookField(
      key: 'warga_id',
      label: 'Warga (pengurus)',
      type: BookFieldType.dropdownRef,
      refTable: TableNames.wargaInduk,
    ),
    const BookField(key: 'jabatan', label: 'Jabatan', type: BookFieldType.text),
    const BookField(
        key: 'nomor_sk_lurah',
        label: 'Nomor SK Lurah',
        type: BookFieldType.text),
    const BookField(
      key: 'masa_bakti_mulai',
      label: 'Masa bakti mulai (tahun)',
      type: BookFieldType.integer,
    ),
    const BookField(
      key: 'masa_bakti_selesai',
      label: 'Masa bakti selesai (tahun)',
      type: BookFieldType.integer,
    ),
    const BookField(key: 'no_hp', label: 'No. HP', type: BookFieldType.text),
  ],
};

/// Kolom yang dipakai untuk menampilkan label opsi dropdown referensi,
/// per tabel referensi. Dipakai bersama `_refDisplayLabel` di halaman form.
const Map<String, List<String>> bookRefDisplayColumns = {
  TableNames.wargaInduk: ['nama_lengkap', 'nomor_kk'],
  TableNames.notulenRapat: ['agenda', 'tanggal_rapat'],
};

String bookRefDisplayLabel(String refTable, Map<String, dynamic> row) {
  final columns = bookRefDisplayColumns[refTable] ?? const ['id'];
  final parts = columns
      .map((c) => row[c])
      .where((v) => v != null && v.toString().isNotEmpty)
      .map((v) => v.toString());
  return parts.isEmpty ? (row['id']?.toString() ?? '-') : parts.join(' • ');
}
