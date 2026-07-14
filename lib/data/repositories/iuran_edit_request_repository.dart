import '../../core/constants/table_names.dart';
import '../datasources/supabase_datasource.dart';
import '../models/iuran_ipl_edit_request.dart';

class IuranEditRequestRepository extends SupabaseDatasource {
  IuranEditRequestRepository(super.client);

  Future<List<IuranIplEditRequest>> getPending() async {
    final rows = await client
        .from(TableNames.iuranIplEditRequests)
        .select()
        .eq('status', 'PENDING')
        .order('created_at');
    return rows.map((e) => IuranIplEditRequest.fromJson(e)).toList();
  }

  Future<List<IuranIplEditRequest>> getMine(String profileId) async {
    final rows = await client
        .from(TableNames.iuranIplEditRequests)
        .select()
        .eq('requested_by', profileId)
        .order('created_at');
    return rows.map((e) => IuranIplEditRequest.fromJson(e)).toList();
  }

  Future<IuranIplEditRequest> create(IuranIplEditRequest request) async {
    final row = await client
        .from(TableNames.iuranIplEditRequests)
        .insert(request.toInsertJson())
        .select()
        .single();
    return IuranIplEditRequest.fromJson(row);
  }

  /// Uses a database RPC with `select ... for update` and `status = PENDING`.
  /// That makes concurrent review safe: if two SUPER_ADMIN users click at the
  /// same time, only the first transaction can claim the pending request.
  Future<IuranIplEditRequest> review({
    required String requestId,
    required bool approve,
    String? reviewNote,
  }) async {
    final row = await client.rpc(
      RpcNames.reviewIuranIplEditRequest,
      params: {
        'p_request_id': requestId,
        'p_approve': approve,
        'p_review_note': reviewNote,
      },
    );
    return IuranIplEditRequest.fromJson(row as Map<String, dynamic>);
  }
}
