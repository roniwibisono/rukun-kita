import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/repositories/repository_providers.dart';

/// Halaman utama untuk role ADMIN / SUPER_ADMIN.
///
/// AI agent: implementasikan tiap menu berikut sebagai halaman terpisah
/// (lihat PRD §5.2):
///   - Permintaan Surat   -> features/admin/permintaan_surat (state machine + realtime)
///   - Retribusi/IPL      -> features/admin/retribusi_iuran
///   - Data Warga         -> features/admin/data_warga (expandable per nomor_kk)
///   - Buku Administrasi  -> features/admin/buku_administrasi (6 kategori CRUD)
class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  static const _menu = [
    _MenuItem(
      'Permintaan Surat',
      Icons.assignment_outlined,
      AppRoutes.adminPermintaanSurat,
    ),
    _MenuItem(
      'Retribusi / IPL',
      Icons.payments_outlined,
      AppRoutes.adminRetribusiIuran,
    ),
    _MenuItem('Data Warga', Icons.groups_outlined, AppRoutes.adminDataWarga),
    _MenuItem(
      'Buku Administrasi',
      Icons.folder_open_outlined,
      AppRoutes.adminBukuAdministrasi,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rukun Kita — Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: _menu
            .map(
              (item) => Card(
                child: InkWell(
                  onTap: () {
                    context.push(item.route);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 40),
                      const SizedBox(height: 12),
                      Text(item.label, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
