class IuranIplEditRequest {
  const IuranIplEditRequest({
    required this.id,
    required this.iuranId,
    required this.requestedBy,
    required this.status,
    this.originalBulanBayar = const [],
    this.originalTotalBayar = 0,
    this.originalKeterangan,
    this.proposedBulanBayar = const [],
    this.proposedTotalBayar = 0,
    this.proposedKeterangan,
    this.requestNote,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    required this.createdAt,
  });

  final String id;
  final String iuranId;
  final String requestedBy;
  final String status;
  final List<int> originalBulanBayar;
  final double originalTotalBayar;
  final String? originalKeterangan;
  final List<int> proposedBulanBayar;
  final double proposedTotalBayar;
  final String? proposedKeterangan;
  final String? requestNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final DateTime createdAt;

  factory IuranIplEditRequest.fromJson(Map<String, dynamic> json) {
    return IuranIplEditRequest(
      id: json['id'] as String,
      iuranId: json['iuran_id'] as String,
      requestedBy: json['requested_by'] as String,
      status: json['status'] as String,
      originalBulanBayar: (json['original_bulan_bayar'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      originalTotalBayar:
          (json['original_total_bayar'] as num?)?.toDouble() ?? 0,
      originalKeterangan: json['original_keterangan'] as String?,
      proposedBulanBayar: (json['proposed_bulan_bayar'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      proposedTotalBayar:
          (json['proposed_total_bayar'] as num?)?.toDouble() ?? 0,
      proposedKeterangan: json['proposed_keterangan'] as String?,
      requestNote: json['request_note'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.parse(json['reviewed_at'] as String),
      reviewNote: json['review_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'iuran_id': iuranId,
        'requested_by': requestedBy,
        'status': status,
        'original_bulan_bayar': originalBulanBayar,
        'original_total_bayar': originalTotalBayar,
        'original_keterangan': originalKeterangan,
        'proposed_bulan_bayar': proposedBulanBayar,
        'proposed_total_bayar': proposedTotalBayar,
        'proposed_keterangan': proposedKeterangan,
        'request_note': requestNote,
      };

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}
