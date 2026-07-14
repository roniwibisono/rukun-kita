/// Mirror tabel `public.surat_masuk` (Buku Register Surat Masuk).
class SuratMasuk {
  const SuratMasuk({
    required this.id,
    this.nomorUrut,
    required this.tanggalTerima,
    required this.nomorSurat,
    required this.tanggalSurat,
    required this.perihal,
    required this.namaPengirim,
    this.disposisiKetua,
  });

  final String id;
  final int? nomorUrut; // serial, auto-generated
  final DateTime tanggalTerima;
  final String nomorSurat;
  final DateTime tanggalSurat;
  final String perihal;
  final String namaPengirim;
  final String? disposisiKetua;

  factory SuratMasuk.fromJson(Map<String, dynamic> json) => SuratMasuk(
        id: json['id'] as String,
        nomorUrut: json['nomor_urut'] as int?,
        tanggalTerima: DateTime.parse(json['tanggal_terima'] as String),
        nomorSurat: json['nomor_surat'] as String,
        tanggalSurat: DateTime.parse(json['tanggal_surat'] as String),
        perihal: json['perihal'] as String,
        namaPengirim: json['nama_pengirim'] as String,
        disposisiKetua: json['disposisi_ketua'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'tanggal_terima': tanggalTerima.toIso8601String().split('T').first,
        'nomor_surat': nomorSurat,
        'tanggal_surat': tanggalSurat.toIso8601String().split('T').first,
        'perihal': perihal,
        'nama_pengirim': namaPengirim,
        'disposisi_ketua': disposisiKetua,
      };
}
