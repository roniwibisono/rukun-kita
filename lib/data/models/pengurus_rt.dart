/// Mirror tabel `public.pengurus_rt` (Buku Data Pengurus RT).
class PengurusRt {
  const PengurusRt({
    required this.id,
    required this.wargaId,
    required this.jabatan,
    required this.nomorSkLurah,
    required this.masaBaktiMulai,
    required this.masaBaktiSelesai,
    required this.noHp,
  });

  final String id;
  final String wargaId; // FK -> warga_induk.id, unique
  final String jabatan;
  final String nomorSkLurah;
  final int masaBaktiMulai;
  final int masaBaktiSelesai;
  final String noHp;

  factory PengurusRt.fromJson(Map<String, dynamic> json) => PengurusRt(
        id: json['id'] as String,
        wargaId: json['warga_id'] as String,
        jabatan: json['jabatan'] as String,
        nomorSkLurah: json['nomor_sk_lurah'] as String,
        masaBaktiMulai: json['masa_bakti_mulai'] as int,
        masaBaktiSelesai: json['masa_bakti_selesai'] as int,
        noHp: json['no_hp'] as String,
      );

  Map<String, dynamic> toInsertJson() => {
        'warga_id': wargaId,
        'jabatan': jabatan,
        'nomor_sk_lurah': nomorSkLurah,
        'masa_bakti_mulai': masaBaktiMulai,
        'masa_bakti_selesai': masaBaktiSelesai,
        'no_hp': noHp,
      };
}
