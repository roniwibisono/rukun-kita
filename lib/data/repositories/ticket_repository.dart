import '../../core/constants/enums.dart';
import '../../core/constants/table_names.dart';
import '../datasources/supabase_datasource.dart';
import '../models/ticket_request.dart';

/// CRUD & realtime stream untuk `ticket_requests`.
///
/// State machine status (lihat PRD §6):
///   BARU -> DIPROSES -> SELESAI -> COMPLETE
///                          |-> PENDING -> COMPLETE
///   BARU/DIPROSES -> BATAL (hanya warga, hanya jika pickup_date masih null)
class TicketRepository extends SupabaseDatasource {
  TicketRepository(super.client);

  /// Stream realtime — otomatis update saat ada INSERT/UPDATE di
  /// `ticket_requests` (tabel ini sudah masuk `supabase_realtime` publication).
  /// RLS tetap berlaku: warga hanya menerima row miliknya/KK-nya, admin semua.
  Stream<List<TicketRequest>> watchAll() {
    return client
        .from(TableNames.ticketRequests)
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows.map((e) => TicketRequest.fromJson(e)).toList());
  }

  Stream<List<TicketRequest>> watchByWarga(String wargaId) {
    return client
        .from(TableNames.ticketRequests)
        .stream(primaryKey: ['id'])
        .eq('warga_id', wargaId)
        .order('created_at')
        .map((rows) => rows.map((e) => TicketRequest.fromJson(e)).toList());
  }

  Future<List<TicketRequest>> getByStatus(TicketStatus status) async {
    final rows = await client
        .from(TableNames.ticketRequests)
        .select()
        .eq('status', status.dbValue)
        .order('created_at');
    return rows.map((e) => TicketRequest.fromJson(e)).toList();
  }

  Future<TicketRequest> create({
    required String wargaId,
    required String jenisKeperluan,
    String? detailKeterangan,
  }) async {
    final row = await client
        .from(TableNames.ticketRequests)
        .insert({
          'warga_id': wargaId,
          'jenis_keperluan': jenisKeperluan,
          'detail_keterangan': detailKeterangan,
        })
        .select()
        .single();
    return TicketRequest.fromJson(row);
  }

  /// Dipanggil admin untuk mengubah status (mis. BARU -> DIPROSES -> SELESAI).
  Future<TicketRequest> updateStatus(
    String ticketId,
    TicketStatus status,
  ) async {
    final row = await client
        .from(TableNames.ticketRequests)
        .update({'status': status.dbValue})
        .eq('id', ticketId)
        .select()
        .single();
    return TicketRequest.fromJson(row);
  }

  /// Warga menetapkan tanggal pengambilan berkas (date picker di UI).
  Future<TicketRequest> setPickupDate(
    String ticketId,
    DateTime pickupDate,
  ) async {
    final row = await client
        .from(TableNames.ticketRequests)
        .update({'pickup_date': pickupDate.toIso8601String()})
        .eq('id', ticketId)
        .select()
        .single();
    return TicketRequest.fromJson(row);
  }

  /// Dipanggil warga untuk membatalkan permintaan.
  /// RLS akan menolak jika status bukan BARU/DIPROSES atau pickup_date sudah terisi.
  Future<TicketRequest> cancel(String ticketId) async {
    final row = await client
        .from(TableNames.ticketRequests)
        .update({'status': TicketStatus.batal.dbValue})
        .eq('id', ticketId)
        .select()
        .single();
    return TicketRequest.fromJson(row);
  }
}
