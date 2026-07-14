import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/ticket_request.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../shared/providers/app_data_providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/status_chip.dart';

class WargaBukuAdministrasiPage extends ConsumerWidget {
  const WargaBukuAdministrasiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buku Administrasi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Induk'),
              Tab(text: 'Surat'),
              Tab(text: 'Ambil'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FamilyBookTab(),
            _TicketBookTab(filterPickup: false),
            _TicketBookTab(filterPickup: true),
          ],
        ),
      ),
    );
  }
}

class _FamilyBookTab extends ConsumerWidget {
  const _FamilyBookTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wargaAsync = ref.watch(wargaListProvider);

    return wargaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Buku induk belum bisa dimuat',
        message: '$error',
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Belum ada data',
            message: 'Data keluarga yang bisa kamu akses akan tampil di sini.',
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
                    Text('NIK ${warga.nik}'),
                    Text('KK ${warga.nomorKk}'),
                    if (warga.hubunganKeluarga != null) ...[
                      const SizedBox(height: 8),
                      Text(warga.hubunganKeluarga!),
                    ],
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: items.length,
        );
      },
    );
  }
}

class _TicketBookTab extends ConsumerWidget {
  const _TicketBookTab({required this.filterPickup});

  final bool filterPickup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(wargaTicketStreamProvider);

    return ticketsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Buku surat belum bisa dimuat',
        message: '$error',
      ),
      data: (tickets) {
        final rows = [...tickets]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final visible = filterPickup
            ? rows
                .where(
                  (ticket) =>
                      ticket.status == TicketStatus.selesai ||
                      ticket.status == TicketStatus.pending,
                )
                .toList()
            : rows;

        if (visible.isEmpty) {
          return EmptyState(
            icon: filterPickup
                ? Icons.event_available_outlined
                : Icons.description_outlined,
            title: filterPickup
                ? 'Belum ada berkas siap ambil'
                : 'Belum ada surat',
            message: filterPickup
                ? 'Berkas yang sudah selesai akan muncul di tab ini.'
                : 'Riwayat surat pengantar akan tersimpan di sini.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) =>
              _TicketBookTile(ticket: visible[index]),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: visible.length,
        );
      },
    );
  }
}

class _TicketBookTile extends ConsumerWidget {
  const _TicketBookTile({required this.ticket});

  final TicketRequest ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPickDate = ticket.status == TicketStatus.selesai ||
        ticket.status == TicketStatus.pending;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(ticket.jenisKeperluan),
        subtitle: Text(
          [
            AppFormatters.date(ticket.createdAt),
            if (ticket.pickupDate != null)
              'Ambil ${AppFormatters.date(ticket.pickupDate!)}',
          ].join(' • '),
        ),
        trailing: TicketStatusChip(ticket.status),
        subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
        onTap: canPickDate ? () => _pickPickupDate(context, ref) : null,
      ),
    );
  }

  Future<void> _pickPickupDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: ticket.pickupDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (selected == null) return;

    try {
      await ref
          .read(ticketRepositoryProvider)
          .setPickupDate(ticket.id, selected);
      ref.invalidate(wargaTicketStreamProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal pengambilan disimpan.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tanggal: $e')),
      );
    }
  }
}
