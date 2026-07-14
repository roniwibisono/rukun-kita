/// Mirror tabel `public.buku_ekspedisi`.
class BukuEkspedisi {
  const BukuEkspedisi({
    required this.id,
    required this.tanggalKirim,
    required this.nomorSurat,
    required this.perihal,
    required this.namaPenerima,
    this.tandaTanganUrl,
  });

  final String id;
  final DateTime tanggalKirim;
  final String nomorSurat;
  final String perihal;
  final String namaPenerima;
  final String? tandaTanganUrl; // path di Supabase Storage

  factory BukuEkspedisi.fromJson(Map<String, dynamic> json) => BukuEkspedisi(
        id: json['id'] as String,
        tanggalKirim: DateTime.parse(json['tanggal_kirim'] as String),
        nomorSurat: json['nomor_surat'] as String,
        perihal: json['perihal'] as String,
        namaPenerima: json['nama_penerima'] as String,
        tandaTanganUrl: json['tanda_tangan_url'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'tanggal_kirim': tanggalKirim.toIso8601String().split('T').first,
        'nomor_surat': nomorSurat,
        'perihal': perihal,
        'nama_penerima': namaPenerima,
        'tanda_tangan_url': tandaTanganUrl,
      };
}
