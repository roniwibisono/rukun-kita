/// Mirror tabel `public.iuran_ipl` (Buku Pembantu Iuran Warga/IPL).
class IuranIpl {
  const IuranIpl({
    required this.id,
    required this.kepalaKeluargaId,
    required this.nomorRumah,
    required this.tahun,
    this.bulanBayar = const [],
    this.totalBayar = 0,
    this.keterangan,
  });

  final String id;
  final String kepalaKeluargaId;
  final String nomorRumah;
  final int tahun;

  /// Daftar bulan (1-12) yang sudah dibayar tahun ini.
  final List<int> bulanBayar;
  final double totalBayar;
  final String? keterangan;

  factory IuranIpl.fromJson(Map<String, dynamic> json) => IuranIpl(
        id: json['id'] as String,
        kepalaKeluargaId: json['kepala_keluarga_id'] as String,
        nomorRumah: json['nomor_rumah'] as String,
        tahun: json['tahun'] as int,
        bulanBayar: (json['bulan_bayar'] as List<dynamic>? ?? [])
            .map((e) => e as int)
            .toList(),
        totalBayar: (json['total_bayar'] as num?)?.toDouble() ?? 0,
        keterangan: json['keterangan'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'kepala_keluarga_id': kepalaKeluargaId,
        'nomor_rumah': nomorRumah,
        'tahun': tahun,
        'bulan_bayar': bulanBayar,
        'total_bayar': totalBayar,
        'keterangan': keterangan,
      };

  bool sudahBayarBulan(int bulan) => bulanBayar.contains(bulan);
}
