/// Mirror tabel `public.buku_tamu`.
class BukuTamu {
  const BukuTamu({
    required this.id,
    required this.tanggalDatang,
    required this.namaTamu,
    required this.alamatAsal,
    required this.tamuKeWargaId,
    this.hubungan,
    required this.keperluan,
    this.tanggalPulang,
  });

  final String id;
  final DateTime tanggalDatang;
  final String namaTamu;
  final String alamatAsal;
  final String tamuKeWargaId; // FK -> warga_induk.id
  final String? hubungan;
  final String keperluan;
  final DateTime? tanggalPulang;

  factory BukuTamu.fromJson(Map<String, dynamic> json) => BukuTamu(
        id: json['id'] as String,
        tanggalDatang: DateTime.parse(json['tanggal_datang'] as String),
        namaTamu: json['nama_tamu'] as String,
        alamatAsal: json['alamat_asal'] as String,
        tamuKeWargaId: json['tamu_ke_warga_id'] as String,
        hubungan: json['hubungan'] as String?,
        keperluan: json['keperluan'] as String,
        tanggalPulang: json['tanggal_pulang'] == null
            ? null
            : DateTime.parse(json['tanggal_pulang'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'tanggal_datang': tanggalDatang.toIso8601String().split('T').first,
        'nama_tamu': namaTamu,
        'alamat_asal': alamatAsal,
        'tamu_ke_warga_id': tamuKeWargaId,
        'hubungan': hubungan,
        'keperluan': keperluan,
        'tanggal_pulang': tanggalPulang?.toIso8601String().split('T').first,
      };
}
