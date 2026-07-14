/// Mirror tabel `public.kas_umum` (Buku Kas Umum).
class KasUmum {
  const KasUmum({
    required this.id,
    required this.tanggalTransaksi,
    required this.uraian,
    this.nomorBukti,
    this.debet = 0,
    this.kredit = 0,
    required this.saldoAkhir,
  });

  final String id;
  final DateTime tanggalTransaksi;
  final String uraian;
  final String? nomorBukti;
  final double debet;
  final double kredit;
  final double saldoAkhir;

  factory KasUmum.fromJson(Map<String, dynamic> json) => KasUmum(
        id: json['id'] as String,
        tanggalTransaksi: DateTime.parse(json['tanggal_transaksi'] as String),
        uraian: json['uraian'] as String,
        nomorBukti: json['nomor_bukti'] as String?,
        debet: (json['debet'] as num?)?.toDouble() ?? 0,
        kredit: (json['kredit'] as num?)?.toDouble() ?? 0,
        saldoAkhir: (json['saldo_akhir'] as num).toDouble(),
      );

  Map<String, dynamic> toInsertJson() => {
        'tanggal_transaksi':
            tanggalTransaksi.toIso8601String().split('T').first,
        'uraian': uraian,
        'nomor_bukti': nomorBukti,
        'debet': debet,
        'kredit': kredit,
        'saldo_akhir': saldoAkhir,
      };
}
