import '../../core/constants/table_names.dart';
import '../datasources/supabase_datasource.dart';
import '../models/iuran_ipl.dart';

/// CRUD untuk `iuran_ipl` (retribusi bulanan / IPL).
class IuranRepository extends SupabaseDatasource {
  IuranRepository(super.client);

  Future<List<IuranIpl>> getByTahun(int tahun) async {
    final rows = await client
        .from(TableNames.iuranIpl)
        .select()
        .eq('tahun', tahun)
        .order('nomor_rumah');
    return rows.map((e) => IuranIpl.fromJson(e)).toList();
  }

  /// Untuk filter status warga aktif/non-aktif (join manual di repository
  /// karena kolom `is_active` ada di `warga_induk`, bukan di `iuran_ipl`).
  /// Gunakan PostgREST embedded resource untuk join dalam 1 request.
  Future<List<IuranIpl>> getByTahunDenganStatusWarga({
    required int tahun,
    required bool isActive,
  }) async {
    final rows = await client
        .from(TableNames.iuranIpl)
        .select('*, warga_induk!inner(is_active)')
        .eq('tahun', tahun)
        .eq('warga_induk.is_active', isActive)
        .order('nomor_rumah');
    return rows.map((e) => IuranIpl.fromJson(e)).toList();
  }

  Future<IuranIpl> upsert(IuranIpl iuran) async {
    final row = await client
        .from(TableNames.iuranIpl)
        .upsert(iuran.toInsertJson())
        .select()
        .single();
    return IuranIpl.fromJson(row);
  }

  Future<IuranIpl> create(IuranIpl iuran) async {
    final row = await client
        .from(TableNames.iuranIpl)
        .insert(iuran.toInsertJson())
        .select()
        .single();
    return IuranIpl.fromJson(row);
  }

  Future<IuranIpl> tandaiBulanDibayar({
    required String iuranId,
    required List<int> bulanBayar,
    required double totalBayar,
  }) async {
    final row = await client
        .from(TableNames.iuranIpl)
        .update({'bulan_bayar': bulanBayar, 'total_bayar': totalBayar})
        .eq('id', iuranId)
        .select()
        .single();
    return IuranIpl.fromJson(row);
  }

  Future<IuranIpl> updateKeterangan({
    required String iuranId,
    required String keterangan,
  }) async {
    final row = await client
        .from(TableNames.iuranIpl)
        .update({'keterangan': keterangan})
        .eq('id', iuranId)
        .select()
        .single();
    return IuranIpl.fromJson(row);
  }
}
