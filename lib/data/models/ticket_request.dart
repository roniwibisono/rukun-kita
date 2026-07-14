import '../../core/constants/enums.dart';

/// Mirror tabel `public.ticket_requests`.
class TicketRequest {
  const TicketRequest({
    required this.id,
    required this.wargaId,
    required this.jenisKeperluan,
    this.detailKeterangan,
    required this.status,
    this.pickupDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String wargaId;
  final String jenisKeperluan;
  final String? detailKeterangan;
  final TicketStatus status;
  final DateTime? pickupDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TicketRequest.fromJson(Map<String, dynamic> json) => TicketRequest(
        id: json['id'] as String,
        wargaId: json['warga_id'] as String,
        jenisKeperluan: json['jenis_keperluan'] as String,
        detailKeterangan: json['detail_keterangan'] as String?,
        status: TicketStatus.fromDb(json['status'] as String),
        pickupDate: json['pickup_date'] == null
            ? null
            : DateTime.parse(json['pickup_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'warga_id': wargaId,
        'jenis_keperluan': jenisKeperluan,
        'detail_keterangan': detailKeterangan,
      };

  TicketRequest copyWith({TicketStatus? status, DateTime? pickupDate}) =>
      TicketRequest(
        id: id,
        wargaId: wargaId,
        jenisKeperluan: jenisKeperluan,
        detailKeterangan: detailKeterangan,
        status: status ?? this.status,
        pickupDate: pickupDate ?? this.pickupDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
