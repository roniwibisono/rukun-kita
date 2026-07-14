import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../shared/providers/app_data_providers.dart';
import '../../shared/widgets/empty_state.dart';

class ProfilKeluargaPage extends ConsumerWidget {
  const ProfilKeluargaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wargaAsync = ref.watch(wargaListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Keluarga')),
      body: wargaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Profil belum bisa dimuat',
          message: '$error',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.family_restroom_outlined,
              title: 'Belum ada data keluarga',
              message: 'Hubungi pengurus RT agar profil keluarga ditautkan.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final warga = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warga.namaLengkap,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _InfoLine(label: 'NIK', value: warga.nik),
                      _InfoLine(label: 'Nomor KK', value: warga.nomorKk),
                      _InfoLine(
                        label: 'Tanggal lahir',
                        value: AppFormatters.date(warga.tanggalLahir),
                      ),
                      if (warga.hubunganKeluarga != null)
                        _InfoLine(
                          label: 'Hubungan',
                          value: warga.hubunganKeluarga!,
                        ),
                      if (warga.pekerjaan != null)
                        _InfoLine(label: 'Pekerjaan', value: warga.pekerjaan!),
                      _InfoLine(label: 'Alamat', value: warga.alamatLengkap),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
    );
  }
}
