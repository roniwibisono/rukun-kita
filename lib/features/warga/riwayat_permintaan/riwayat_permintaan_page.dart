import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/ticket_request.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../shared/providers/app_data_providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/status_chip.dart';

class RiwayatPermintaanPage extends ConsumerWidget {
  const RiwayatPermintaanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(wargaTicketStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Permintaan')),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Riwayat belum bisa dimuat',
          message: '$error',
        ),
        data: (tickets) {
          final sorted = [...tickets]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (sorted.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'Belum ada permintaan',
              message: 'Pengajuan surat yang kamu kirim akan muncul di sini.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(wargaTicketStreamProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) =>
                  _TicketCard(ticket: sorted[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: sorted.length,
            ),
          );
        },
      ),
    );
  }
}

class _TicketCard extends ConsumerWidget {
  const _TicketCard({required this.ticket});

  final TicketRequest ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel =
        ticket.status.bolehDibatalkanWarga && ticket.pickupDate == null;
    final canSetPickup = ticket.status == TicketStatus.selesai ||
        ticket.status == TicketStatus.pending;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ticket.jenisKeperluan,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TicketStatusChip(ticket.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Diajukan ${AppFormatters.date(ticket.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (ticket.detailKeterangan != null &&
                ticket.detailKeterangan!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(ticket.detailKeterangan!),
            ],
            if (ticket.pickupDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tanggal ambil: ${AppFormatters.date(ticket.pickupDate!)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (canCancel || canSetPickup) ...[
              const SizedBox(height: 12),
              if (canSetPickup)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPickupDate(context, ref),
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Tanggal ambil'),
                  ),
                ),
              if (canCancel)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancel(context, ref),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Batalkan'),
                  ),
                ),
            ],
          ],
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan tanggal: $e')));
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan permintaan?'),
        content: const Text(
          'Permintaan yang dibatalkan tidak bisa diproses admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(ticketRepositoryProvider).cancel(ticket.id);
      ref.invalidate(wargaTicketStreamProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permintaan dibatalkan.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membatalkan: $e')));
    }
  }
}
