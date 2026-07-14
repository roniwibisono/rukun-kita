import '../../core/constants/enums.dart';

/// Mirror tabel `public.inventaris_rt`.
class InventarisRt {
  const InventarisRt({
    required this.id,
    required this.namaBarang,
    this.merekTipe,
    this.jumlah = 1,
    this.tanggalPerolehan,
    this.asalBarang,
    this.kondisi = KondisiBarang.baik,
  });

  final String id;
  final String namaBarang;
  final String? merekTipe;
  final int jumlah;
  final DateTime? tanggalPerolehan;
  final String? asalBarang;
  final KondisiBarang kondisi;

  factory InventarisRt.fromJson(Map<String, dynamic> json) => InventarisRt(
        id: json['id'] as String,
        namaBarang: json['nama_barang'] as String,
        merekTipe: json['merek_tipe'] as String?,
        jumlah: json['jumlah'] as int? ?? 1,
        tanggalPerolehan: json['tanggal_perolehan'] == null
            ? null
            : DateTime.parse(json['tanggal_perolehan'] as String),
        asalBarang: json['asal_barang'] as String?,
        kondisi: KondisiBarang.fromDb(json['kondisi'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'nama_barang': namaBarang,
        'merek_tipe': merekTipe,
        'jumlah': jumlah,
        'tanggal_perolehan':
            tanggalPerolehan?.toIso8601String().split('T').first,
        'asal_barang': asalBarang,
        'kondisi': kondisi.dbValue,
      };
}
