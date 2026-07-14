import '../../core/constants/table_names.dart';
import '../datasources/supabase_datasource.dart';
import '../models/warga_induk.dart';

/// CRUD `warga_induk` + helper untuk grouping per Kartu Keluarga.
///
/// Catatan desain (lihat PRD §5.2): grouping "kepala keluarga -> anggota"
/// di UI admin sebaiknya berbasis `nomor_kk`, BUKAN `parent_id` semata,
/// karena tidak semua keluarga punya parent_id terisi eksplisit.
class WargaRepository extends SupabaseDatasource {
  WargaRepository(super.client);

  /// Semua warga yang terkait dengan user yang sedang login
  /// (RLS otomatis membatasi: admin lihat semua, warga hanya KK sendiri).
  Future<List<WargaInduk>> getAll({bool? isActive}) async {
    var query = client.from(TableNames.wargaInduk).select();
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    final rows = await query.order('nama_lengkap');
    return rows.map((e) => WargaInduk.fromJson(e)).toList();
  }

  Future<WargaInduk> getById(String id) async {
    final row =
        await client.from(TableNames.wargaInduk).select().eq('id', id).single();
    return WargaInduk.fromJson(row);
  }

  Future<List<WargaInduk>> getByNomorKk(String nomorKk) async {
    final rows = await client
        .from(TableNames.wargaInduk)
        .select()
        .eq('nomor_kk', nomorKk)
        .order('hubungan_keluarga');
    return rows.map((e) => WargaInduk.fromJson(e)).toList();
  }

  /// Group semua warga per `nomor_kk` — dipakai admin untuk tabel expandable
  /// (kepala keluarga sebagai root row, anggota lain sebagai child saat expand).
  Future<Map<String, List<WargaInduk>>> getGroupedByKk({bool? isActive}) async {
    final all = await getAll(isActive: isActive);
    final grouped = <String, List<WargaInduk>>{};
    for (final warga in all) {
      grouped.putIfAbsent(warga.nomorKk, () => []).add(warga);
    }
    return grouped;
  }

  Future<WargaInduk> create(WargaInduk warga) async {
    final row = await client
        .from(TableNames.wargaInduk)
        .insert(warga.toInsertJson())
        .select()
        .single();
    return WargaInduk.fromJson(row);
  }

  Future<WargaInduk> update(String id, Map<String, dynamic> changes) async {
    final row = await client
        .from(TableNames.wargaInduk)
        .update(changes)
        .eq('id', id)
        .select()
        .single();
    return WargaInduk.fromJson(row);
  }

  Future<void> delete(String id) async {
    await client.from(TableNames.wargaInduk).delete().eq('id', id);
  }

  /// Klaim row `warga_induk` yang sudah ada oleh warga yang baru login,
  /// dengan memanggil RPC `link_warga_profile` yang sudah ada di DB.
  Future<WargaInduk> linkProfile({
    required String nik,
    required String nomorKk,
  }) async {
    final rows = await client.rpc(
      RpcNames.linkWargaProfile,
      params: {'p_nik': nik, 'p_nomor_kk': nomorKk},
    );
    final list = (rows as List).map((e) => WargaInduk.fromJson(e)).toList();
    if (list.isEmpty) {
      throw StateError(
        'NIK/Nomor KK tidak ditemukan atau sudah ditautkan ke akun lain.',
      );
    }
    return list.first;
  }
}
