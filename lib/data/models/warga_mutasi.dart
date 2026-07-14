import '../../core/constants/enums.dart';

/// Mirror tabel `public.warga_mutasi` (Buku Data Mutasi Penduduk).
class WargaMutasi {
  const WargaMutasi({
    required this.id,
    required this.namaWarga,
    required this.alamatLamaBaru,
    required this.jenisMutasi,
    required this.tanggalMutasi,
    this.keterangan,
  });

  final String id;
  final String namaWarga;
  final String alamatLamaBaru;
  final MutasiType jenisMutasi;
  final DateTime tanggalMutasi;
  final String? keterangan;

  factory WargaMutasi.fromJson(Map<String, dynamic> json) => WargaMutasi(
        id: json['id'] as String,
        namaWarga: json['nama_warga'] as String,
        alamatLamaBaru: json['alamat_lama_baru'] as String,
        jenisMutasi: MutasiType.fromDb(json['jenis_mutasi'] as String),
        tanggalMutasi: DateTime.parse(json['tanggal_mutasi'] as String),
        keterangan: json['keterangan'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'nama_warga': namaWarga,
        'alamat_lama_baru': alamatLamaBaru,
        'jenis_mutasi': jenisMutasi.dbValue,
        'tanggal_mutasi': tanggalMutasi.toIso8601String().split('T').first,
        'keterangan': keterangan,
      };
}
