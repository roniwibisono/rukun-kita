import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../shared/widgets/empty_state.dart';
import 'book_form_dialog.dart';
import 'buku_administrasi_field_config.dart';

class AdminBukuAdministrasiPage extends ConsumerWidget {
  const AdminBukuAdministrasiPage({super.key});

  static const _tables = [
    _BookTable(
      'Buku Induk',
      'warga_induk',
      Icons.groups_outlined,
      // Dikelola lewat halaman "Data Warga" (grouping per KK, klaim profil,
      // dll) — di sini hanya tampilan baca agar tidak ada dua jalur tulis
      // untuk data yang sama.
      readOnly: true,
    ),
    _BookTable('Mutasi', 'warga_mutasi', Icons.swap_horiz_outlined),
    _BookTable('Warga Sementara', 'warga_sementara', Icons.person_pin_outlined),
    _BookTable('Surat Masuk', 'surat_masuk', Icons.mark_email_read_outlined),
    _BookTable('Surat Keluar', 'surat_keluar', Icons.outgoing_mail),
    _BookTable('Ekspedisi', 'buku_ekspedisi', Icons.local_shipping_outlined),
    _BookTable('Kas Umum', 'kas_umum', Icons.account_balance_wallet_outlined),
    _BookTable('Tamu', 'buku_tamu', Icons.badge_outlined),
    _BookTable('Inventaris', 'inventaris_rt', Icons.inventory_2_outlined),
    _BookTable('Notulen', 'notulen_rapat', Icons.summarize_outlined),
    _BookTable('Presensi', 'presensi_rapat', Icons.fact_check_outlined),
    _BookTable('Pengurus', 'pengurus_rt', Icons.admin_panel_settings_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: _tables.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buku Administrasi'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final table in _tables) Tab(text: table.label)],
          ),
        ),
        body: TabBarView(
          children: [for (final table in _tables) _BookTableView(table: table)],
        ),
      ),
    );
  }
}

class _BookTableView extends ConsumerStatefulWidget {
  const _BookTableView({required this.table});

  final _BookTable table;

  @override
  ConsumerState<_BookTableView> createState() => _BookTableViewState();
}

class _BookTableViewState extends ConsumerState<_BookTableView> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await ref
        .read(supabaseClientProvider)
        .from(widget.table.name)
        .select(_selectColumns());
    return rows.cast<Map<String, dynamic>>();
  }

  String _selectColumns() {
    if (widget.table.readOnly) {
      return [
        'id',
        'nama_lengkap',
        'nik',
        'nomor_kk',
        'hubungan_keluarga',
        'alamat_lengkap',
        'is_active',
        'created_at',
      ].join(',');
    }

    final fields =
        bukuAdministrasiFieldConfig[widget.table.name] ?? const <BookField>[];
    return {'id', 'created_at', for (final field in fields) field.key}.join(
      ',',
    );
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.table.readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: '${widget.table.label} belum bisa dimuat',
              message: '${snapshot.error}',
            );
          }

          final rows = snapshot.data ?? [];

          return Column(
            children: [
              if (widget.table.readOnly) _ReadOnlyBanner(table: widget.table),
              Expanded(
                child: rows.isEmpty
                    ? EmptyState(
                        icon: widget.table.icon,
                        title: '${widget.table.label} kosong',
                        message: widget.table.readOnly
                            ? 'Belum ada data warga. Tambahkan lewat halaman Data Warga.'
                            : 'Tambah catatan baru lewat tombol di kanan bawah.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            widget.table.readOnly ? 16 : 96,
                          ),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return Card(
                              key: ValueKey(
                                  row['id'] ?? '${widget.table.name}-$index'),
                              child: ExpansionTile(
                                leading: Icon(widget.table.icon),
                                title: Text(_rowTitle(row)),
                                subtitle: Text(_rowSubtitle(row)),
                                childrenPadding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                children: [
                                  _RowDetail(row: row),
                                  if (!widget.table.readOnly) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _openEditor(row: row),
                                          icon: const Icon(Icons.edit_outlined),
                                          label: const Text('Edit'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _delete(row),
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          label: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemCount: rows.length,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _rowTitle(Map<String, dynamic> row) {
    for (final key in const [
      'nama_lengkap',
      'nama_barang',
      'nama_tamu',
      'nama_warga',
      'jabatan',
      'perihal',
      'agenda',
      'uraian',
      'nomor_surat',
      'id',
    ]) {
      final value = row[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return 'Catatan';
  }

  String _rowSubtitle(Map<String, dynamic> row) {
    final parts = <String>[];
    for (final key in const [
      'tanggal_terima',
      'tanggal_keluar',
      'tanggal_transaksi',
      'tanggal_datang',
      'tanggal_rapat',
      'tanggal_mutasi',
      'created_at',
      'nomor_kk',
    ]) {
      final value = row[key];
      if (value != null && value.toString().isNotEmpty) {
        parts.add('$key: $value');
      }
    }
    return parts.isEmpty ? widget.table.name : parts.take(2).join(' • ');
  }

  Future<void> _openEditor({Map<String, dynamic>? row}) async {
    final fields = bukuAdministrasiFieldConfig[widget.table.name];
    if (fields == null) {
      // Seharusnya tidak terjadi — setiap tabel yang bisa ditulis harus
      // punya entri di bukuAdministrasiFieldConfig.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belum ada form untuk ${widget.table.label}.')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BookFormDialog(
        title: row == null
            ? 'Tambah ${widget.table.label}'
            : 'Edit ${widget.table.label}',
        fields: fields,
        initialRow: row,
        supabase: ref.read(supabaseClientProvider),
      ),
    );
    if (result == null) return;

    try {
      final client = ref.read(supabaseClientProvider).from(widget.table.name);
      if (row == null) {
        await client.insert(result);
      } else {
        await client.update(result).eq('id', row['id'] as String);
      }
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan buku administrasi disimpan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text('Aksi ini akan menghapus row dari tabel Supabase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(supabaseClientProvider)
          .from(widget.table.name)
          .delete()
          .eq('id', row['id'] as String);
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Catatan dihapus.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }
}

/// Menampilkan isi row sebagai daftar label:nilai yang rapi, menggantikan
/// dump JSON mentah yang sebelumnya dipakai di tampilan expand.
class _RowDetail extends StatelessWidget {
  const _RowDetail({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final entries = row.entries.where((e) => e.key != 'id').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ),
                Expanded(
                  child: Text('${entry.value ?? '-'}'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner({required this.table});

  final _BookTable table;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tampilan baca saja. Tambah/ubah data warga lewat halaman Data Warga.',
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.adminDataWarga),
            child: const Text('Buka'),
          ),
        ],
      ),
    );
  }
}

class _BookTable {
  const _BookTable(this.label, this.name, this.icon, {this.readOnly = false});

  final String label;
  final String name;
  final IconData icon;
  final bool readOnly;
}
