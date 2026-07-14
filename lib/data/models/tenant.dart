/// Mirror tabel `public.tenants` — fondasi multi-tenant untuk fase SaaS
/// mendatang (tidak dipakai aktif di MVP single-RT).
class Tenant {
  const Tenant({
    required this.id,
    required this.kodeRt,
    required this.namaRt,
    required this.rw,
    required this.kelurahan,
    required this.kecamatan,
    required this.kota,
    required this.provinsi,
    this.status = 'TRIAL',
    required this.createdAt,
  });

  final String id;
  final String kodeRt;
  final String namaRt;
  final String rw;
  final String kelurahan;
  final String kecamatan;
  final String kota;
  final String provinsi;
  final String status; // TRIAL | ACTIVE | SUSPENDED
  final DateTime createdAt;

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
        id: json['id'] as String,
        kodeRt: json['kode_rt'] as String,
        namaRt: json['nama_rt'] as String,
        rw: json['rw'] as String,
        kelurahan: json['kelurahan'] as String,
        kecamatan: json['kecamatan'] as String,
        kota: json['kota'] as String,
        provinsi: json['provinsi'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
