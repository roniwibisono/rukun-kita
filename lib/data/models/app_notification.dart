/// Mirror tabel `public.app_notifications`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.wargaId,
    this.ticketId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String wargaId;
  final String? ticketId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        wargaId: json['warga_id'] as String,
        ticketId: json['ticket_id'] as String?,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'warga_id': wargaId,
        if (ticketId != null) 'ticket_id': ticketId,
        'type': type,
        'title': title,
        'body': body,
      };
}
