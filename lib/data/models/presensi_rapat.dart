/// Mirror tabel `public.presensi_rapat`.
class PresensiRapat {
  const PresensiRapat({
    required this.id,
    required this.rapatId,
    required this.wargaId,
  });

  final String id;
  final String rapatId; // FK -> notulen_rapat.id
  final String wargaId; // FK -> warga_induk.id

  factory PresensiRapat.fromJson(Map<String, dynamic> json) => PresensiRapat(
        id: json['id'] as String,
        rapatId: json['rapat_id'] as String,
        wargaId: json['warga_id'] as String,
      );

  Map<String, dynamic> toInsertJson() => {
        'rapat_id': rapatId,
        'warga_id': wargaId,
      };
}
