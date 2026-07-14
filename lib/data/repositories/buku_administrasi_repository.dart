import '../../core/constants/table_names.dart';
import '../datasources/supabase_datasource.dart';
import '../models/buku_ekspedisi.dart';
import '../models/buku_tamu.dart';
import '../models/inventaris_rt.dart';
import '../models/kas_umum.dart';
import '../models/notulen_rapat.dart';
import '../models/pengurus_rt.dart';
import '../models/presensi_rapat.dart';
import '../models/surat_keluar.dart';
import '../models/surat_masuk.dart';
import '../models/warga_mutasi.dart';
import '../models/warga_sementara.dart';

/// Generic CRUD repository untuk tabel buku administrasi yang polanya sama:
/// list, create, update, delete — tanpa business rule khusus di luar RLS
/// (semua tabel ini sudah punya policy `admin_all_*` di DB).
///
/// AI agent: daripada duplikasi boilerplate CRUD 10x untuk tiap tabel,
/// pakai generic class ini dengan generic type `T` + fungsi mapper.
/// Contoh pemakaian ada di bagian bawah file ini (`SuratMasukRepository`, dst).
class GenericCrudRepository<T> extends SupabaseDatasource {
  GenericCrudRepository(
    super.client, {
    required this.tableName,
    required this.fromJson,
    required this.toInsertJson,
    this.orderBy,
  });

  final String tableName;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toInsertJson;
  final String? orderBy;

  Future<List<T>> getAll() async {
    var query = client.from(tableName).select();
    final rows = orderBy != null ? await query.order(orderBy!) : await query;
    return rows.map((e) => fromJson(e)).toList();
  }

  Future<T> getById(String id) async {
    final row = await client.from(tableName).select().eq('id', id).single();
    return fromJson(row);
  }

  Future<T> create(T item) async {
    final row = await client
        .from(tableName)
        .insert(toInsertJson(item))
        .select()
        .single();
    return fromJson(row);
  }

  Future<T> update(String id, Map<String, dynamic> changes) async {
    final row = await client
        .from(tableName)
        .update(changes)
        .eq('id', id)
        .select()
        .single();
    return fromJson(row);
  }

  Future<void> delete(String id) async {
    await client.from(tableName).delete().eq('id', id);
  }
}

// ---------------------------------------------------------------------------
// Instansiasi konkret per tabel — inject via Riverpod provider (lihat
// core/router atau file provider terpisah saat integrasi state management).
// ---------------------------------------------------------------------------

class SuratMasukRepository extends GenericCrudRepository<SuratMasuk> {
  SuratMasukRepository(super.client)
      : super(
          tableName: TableNames.suratMasuk,
          fromJson: SuratMasuk.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
          orderBy: 'tanggal_terima',
        );
}

class SuratKeluarRepository extends GenericCrudRepository<SuratKeluar> {
  SuratKeluarRepository(super.client)
      : super(
          tableName: TableNames.suratKeluar,
          fromJson: SuratKeluar.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
          orderBy: 'tanggal_keluar',
        );
}

class BukuEkspedisiRepository extends GenericCrudRepository<BukuEkspedisi> {
  BukuEkspedisiRepository(super.client)
      : super(
          tableName: TableNames.bukuEkspedisi,
          fromJson: BukuEkspedisi.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
          orderBy: 'tanggal_kirim',
        );
}

class KasUmumRepository extends GenericCrudRepository<KasUmum> {
  KasUmumRepository(super.client)
      : super(
          tableName: TableNames.kasUmum,
          fromJson: KasUmum.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
          orderBy: 'tanggal_transaksi',
        );
}

class BukuTamuRepository extends GenericCrudRepository<BukuTamu> {
  BukuTamuRepository(super.client)
      : super(
          tableName: TableNames.bukuTamu,
          fromJson: BukuTamu.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
          orderBy: 'tanggal_datang',
        );
}

class InventarisRtRepository extends GenericCrudRepository<InventarisRt> {
  InventarisRtRepository(super.client)
      : super(
          tableName: TableNames.inventarisRt,
          fromJson: InventarisRt.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
          orderBy: 'nama_barang',
        );
}

class NotulenRapatRepository extends GenericCrudRepository<NotulenRapat> {
  NotulenRapatRepository(super.client)
      : super(
          tableName: TableNames.notulenRapat,
          fromJson: NotulenRapat.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
          orderBy: 'tanggal_rapat',
        );
}

class PresensiRapatRepository extends GenericCrudRepository<PresensiRapat> {
  PresensiRapatRepository(super.client)
      : super(
          tableName: TableNames.presensiRapat,
          fromJson: PresensiRapat.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
        );
}

class PengurusRtRepository extends GenericCrudRepository<PengurusRt> {
  PengurusRtRepository(super.client)
      : super(
          tableName: TableNames.pengurusRt,
          fromJson: PengurusRt.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
          orderBy: 'jabatan',
        );
}

class WargaMutasiRepository extends GenericCrudRepository<WargaMutasi> {
  WargaMutasiRepository(super.client)
      : super(
          tableName: TableNames.wargaMutasi,
          fromJson: WargaMutasi.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
          orderBy: 'tanggal_mutasi',
        );
}

class WargaSementaraRepository extends GenericCrudRepository<WargaSementara> {
  WargaSementaraRepository(super.client)
      : super(
          tableName: TableNames.wargaSementara,
          fromJson: WargaSementara.fromJson,
          toInsertJson: (e) => e.toInsertJson(),
          orderBy: 'tanggal_mulai',
        );
}
