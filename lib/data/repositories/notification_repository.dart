import '../../core/constants/table_names.dart';
import '../datasources/supabase_datasource.dart';
import '../models/app_notification.dart';

/// CRUD & realtime stream untuk `app_notifications`.
class NotificationRepository extends SupabaseDatasource {
  NotificationRepository(super.client);

  /// Stream realtime notifikasi milik warga tertentu — dipakai untuk
  /// badge unread counter + local notification trigger (lihat PRD §10 Fase 4).
  Stream<List<AppNotification>> watchByWarga(String wargaId) {
    return client
        .from(TableNames.appNotifications)
        .stream(primaryKey: ['id'])
        .eq('warga_id', wargaId)
        .order('created_at')
        .map((rows) => rows.map((e) => AppNotification.fromJson(e)).toList());
  }

  Future<int> countUnread(String wargaId) async {
    final rows = await client
        .from(TableNames.appNotifications)
        .select('id')
        .eq('warga_id', wargaId)
        .eq('is_read', false);
    return rows.length;
  }

  Future<void> markAsRead(String notificationId) async {
    await client
        .from(TableNames.appNotifications)
        .update({'is_read': true}).eq('id', notificationId);
  }

  /// Dipanggil admin (atau Edge Function) saat status tiket berubah,
  /// misalnya ke SELESAI, untuk memberi tahu warga terkait.
  Future<AppNotification> create(AppNotification notification) async {
    final row = await client
        .from(TableNames.appNotifications)
        .insert(notification.toInsertJson())
        .select()
        .single();
    return AppNotification.fromJson(row);
  }
}
