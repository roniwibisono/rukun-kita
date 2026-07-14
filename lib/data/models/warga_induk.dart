/// Mirror tabel `public.warga_induk` (Buku Induk Penduduk).
class WargaInduk {
  const WargaInduk({
    required this.id,
    this.profileId,
    this.parentId,
    required this.namaLengkap,
    required this.nomorKk,
    required this.nik,
    this.jenisKelamin,
    this.tempatLahir,
    required this.tanggalLahir,
    this.agama,
    this.pendidikan,
    this.pekerjaan,
    this.statusPernikahan,
    this.hubunganKeluarga,
    required this.alamatLengkap,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String? profileId;
  final String? parentId;
  final String namaLengkap;
  final String nomorKk;
  final String nik;
  final String? jenisKelamin; // 'L' | 'P'
  final String? tempatLahir;
  final DateTime tanggalLahir;
  final String? agama;
  final String? pendidikan;
  final String? pekerjaan;
  final String? statusPernikahan;
  final String? hubunganKeluarga;
  final String alamatLengkap;
  final bool isActive;
  final DateTime createdAt;

  factory WargaInduk.fromJson(Map<String, dynamic> json) => WargaInduk(
        id: json['id'] as String,
        profileId: json['profile_id'] as String?,
        parentId: json['parent_id'] as String?,
        namaLengkap: json['nama_lengkap'] as String,
        nomorKk: json['nomor_kk'] as String,
        nik: json['nik'] as String,
        jenisKelamin: json['jenis_kelamin'] as String?,
        tempatLahir: json['tempat_lahir'] as String?,
        tanggalLahir: DateTime.parse(json['tanggal_lahir'] as String),
        agama: json['agama'] as String?,
        pendidikan: json['pendidikan'] as String?,
        pekerjaan: json['pekerjaan'] as String?,
        statusPernikahan: json['status_pernikahan'] as String?,
        hubunganKeluarga: json['hubungan_keluarga'] as String?,
        alamatLengkap: json['alamat_lengkap'] as String,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// Untuk insert/update — jangan sertakan `id`/`created_at` saat insert baru
  /// (biarkan default DB yang mengisi).
  Map<String, dynamic> toInsertJson() => {
        if (profileId != null) 'profile_id': profileId,
        if (parentId != null) 'parent_id': parentId,
        'nama_lengkap': namaLengkap,
        'nomor_kk': nomorKk,
        'nik': nik,
        'jenis_kelamin': jenisKelamin,
        'tempat_lahir': tempatLahir,
        'tanggal_lahir': tanggalLahir.toIso8601String().split('T').first,
        'agama': agama,
        'pendidikan': pendidikan,
        'pekerjaan': pekerjaan,
        'status_pernikahan': statusPernikahan,
        'hubungan_keluarga': hubunganKeluarga,
        'alamat_lengkap': alamatLengkap,
        'is_active': isActive,
      };
}
