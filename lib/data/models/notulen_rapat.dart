/// Mirror tabel `public.notulen_rapat`.
class NotulenRapat {
  const NotulenRapat({
    required this.id,
    required this.tanggalRapat,
    required this.waktuRapat,
    required this.tempatRapat,
    required this.agenda,
    required this.pembahasan,
    required this.hasilKeputusan,
    required this.notulisNama,
  });

  final String id;
  final DateTime tanggalRapat;
  final String waktuRapat; // format "HH:mm:ss" dari kolom `time`
  final String tempatRapat;
  final String agenda;
  final String pembahasan;
  final String hasilKeputusan;
  final String notulisNama;

  factory NotulenRapat.fromJson(Map<String, dynamic> json) => NotulenRapat(
        id: json['id'] as String,
        tanggalRapat: DateTime.parse(json['tanggal_rapat'] as String),
        waktuRapat: json['waktu_rapat'] as String,
        tempatRapat: json['tempat_rapat'] as String,
        agenda: json['agenda'] as String,
        pembahasan: json['pembahasan'] as String,
        hasilKeputusan: json['hasil_keputusan'] as String,
        notulisNama: json['notulis_nama'] as String,
      );

  Map<String, dynamic> toInsertJson() => {
        'tanggal_rapat': tanggalRapat.toIso8601String().split('T').first,
        'waktu_rapat': waktuRapat,
        'tempat_rapat': tempatRapat,
        'agenda': agenda,
        'pembahasan': pembahasan,
        'hasil_keputusan': hasilKeputusan,
        'notulis_nama': notulisNama,
      };
}
