import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/repositories/repository_providers.dart';

/// Halaman utama untuk role WARGA.
///
/// AI agent: implementasikan tiap menu berikut sebagai halaman terpisah
/// di folder feature masing-masing (lihat PRD §5.1):
///   - Ajukan Surat            -> features/warga/ajukan_surat
///   - Riwayat Permintaan Saya -> features/warga/riwayat_permintaan
///   - Buku Administrasi       -> features/warga/buku_administrasi
///   - Notifikasi              -> features/warga/notifikasi
class WargaHomePage extends ConsumerWidget {
  const WargaHomePage({super.key});

  static const _menu = [
    _MenuItem(
      'Ajukan Surat',
      Icons.description_outlined,
      AppRoutes.wargaAjukanSurat,
    ),
    _MenuItem(
      'Riwayat Permintaan',
      Icons.history,
      AppRoutes.wargaRiwayatPermintaan,
    ),
    _MenuItem(
      'Buku Administrasi',
      Icons.menu_book_outlined,
      AppRoutes.wargaBukuAdministrasi,
    ),
    _MenuItem(
      'Notifikasi',
      Icons.notifications_outlined,
      AppRoutes.wargaNotifikasi,
    ),
    _MenuItem(
      'Profil Keluarga',
      Icons.family_restroom_outlined,
      AppRoutes.wargaProfilKeluarga,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rukun Kita — Warga'),
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
