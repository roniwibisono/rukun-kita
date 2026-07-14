/// Mirror tabel `public.warga_sementara` (Buku Data Penduduk Sementara).
class WargaSementara {
  const WargaSementara({
    required this.id,
    required this.namaLengkap,
    required this.nikPaspor,
    this.alamatAsal,
    this.pekerjaan,
    this.penanggungJawab,
    required this.tanggalMulai,
    this.tanggalKeluar,
  });

  final String id;
  final String namaLengkap;
  final String nikPaspor;
  final String? alamatAsal;
  final String? pekerjaan;
  final String? penanggungJawab;
  final DateTime tanggalMulai;
  final DateTime? tanggalKeluar;

  factory WargaSementara.fromJson(Map<String, dynamic> json) => WargaSementara(
        id: json['id'] as String,
        namaLengkap: json['nama_lengkap'] as String,
        nikPaspor: json['nik_paspor'] as String,
        alamatAsal: json['alamat_asal'] as String?,
        pekerjaan: json['pekerjaan'] as String?,
        penanggungJawab: json['penanggung_jawab'] as String?,
        tanggalMulai: DateTime.parse(json['tanggal_mulai'] as String),
        tanggalKeluar: json['tanggal_keluar'] == null
            ? null
            : DateTime.parse(json['tanggal_keluar'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'nama_lengkap': namaLengkap,
        'nik_paspor': nikPaspor,
        'alamat_asal': alamatAsal,
        'pekerjaan': pekerjaan,
        'penanggung_jawab': penanggungJawab,
        'tanggal_mulai': tanggalMulai.toIso8601String().split('T').first,
        'tanggal_keluar': tanggalKeluar?.toIso8601String().split('T').first,
      };
}
