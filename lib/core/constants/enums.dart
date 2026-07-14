// Semua enum di file ini WAJIB mirror 1:1 dengan `create type ... as enum (...)`
// di migration Supabase. Jangan ubah value string tanpa mengubah DB juga.

enum UserRole {
  warga('WARGA'),
  admin('ADMIN'),
  superAdmin('SUPER_ADMIN');

  const UserRole(this.dbValue);
  final String dbValue;

  static UserRole fromDb(String value) => UserRole.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => throw ArgumentError('Unknown user_role: $value'),
      );
}

enum TicketStatus {
  baru('BARU'),
  diproses('DIPROSES'),
  selesai('SELESAI'),
  complete('COMPLETE'),
  pending('PENDING'),
  batal('BATAL');

  const TicketStatus(this.dbValue);
  final String dbValue;

  static TicketStatus fromDb(String value) => TicketStatus.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => throw ArgumentError('Unknown ticket_status: $value'),
      );

  /// Warga hanya boleh membatalkan jika status masih di salah satu state ini
  /// DAN `pickup_date` masih null — mirror dari RLS policy
  /// `tickets_update_related_cancel_or_admin`.
  bool get bolehDibatalkanWarga =>
      this == TicketStatus.baru || this == TicketStatus.diproses;
}

enum MutasiType {
  lahir('LAHIR'),
  meninggal('MENINGGAL'),
  pindahMasuk('PINDAH_MASUK'),
  pindahKeluar('PINDAH_KELUAR');

  const MutasiType(this.dbValue);
  final String dbValue;

  static MutasiType fromDb(String value) => MutasiType.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => throw ArgumentError('Unknown mutasi_type: $value'),
      );
}

enum KondisiBarang {
  baik('BAIK'),
  rusak('RUSAK');

  const KondisiBarang(this.dbValue);
  final String dbValue;

  static KondisiBarang fromDb(String value) => KondisiBarang.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => throw ArgumentError('Unknown kondisi_barang: $value'),
      );
}

/// Jenis keperluan surat pengantar — bukan enum di DB (kolom `jenis_keperluan`
/// adalah varchar bebas), tapi kita batasi pilihannya di UI agar konsisten.
enum JenisKeperluanSurat {
  ktpBaruHilang('Pengantar KTP Baru/Hilang'),
  kartuKeluarga('Pengantar Kartu Keluarga (KK)'),
  aktaLahir('Pengantar Akta Kelahiran'),
  aktaKematian('Pengantar Akta Kematian'),
  numpangNikah('Pengantar Numpang Nikah/KUA'),
  sktm('Pengantar SKTM/Bantuan Sosial'),
  domisili('Surat Keterangan Domisili'),
  pindah('Surat Keterangan Pindah');

  const JenisKeperluanSurat(this.label);
  final String label;
}
