/// Mirror tabel `public.surat_keluar` (Buku Register Surat Keluar).
class SuratKeluar {
  const SuratKeluar({
    required this.id,
    this.nomorUrutSurat,
    required this.tanggalKeluar,
    required this.alamatTujuan,
    required this.perihal,
    required this.namaPenandatangan,
    this.keterangan,
  });

  final String id;
  final int? nomorUrutSurat;
  final DateTime tanggalKeluar;
  final String alamatTujuan;
  final String perihal;
  final String namaPenandatangan;
  final String? keterangan;

  factory SuratKeluar.fromJson(Map<String, dynamic> json) => SuratKeluar(
        id: json['id'] as String,
        nomorUrutSurat: json['nomor_urut_surat'] as int?,
        tanggalKeluar: DateTime.parse(json['tanggal_keluar'] as String),
        alamatTujuan: json['alamat_tujuan'] as String,
        perihal: json['perihal'] as String,
        namaPenandatangan: json['nama_penandatangan'] as String,
        keterangan: json['keterangan'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'tanggal_keluar': tanggalKeluar.toIso8601String().split('T').first,
        'alamat_tujuan': alamatTujuan,
        'perihal': perihal,
        'nama_penandatangan': namaPenandatangan,
        'keterangan': keterangan,
      };
}
