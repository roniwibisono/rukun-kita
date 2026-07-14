import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/ticket_request.dart';
import '../../../data/models/warga_induk.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../shared/providers/app_data_providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/status_chip.dart';

class PermintaanSuratPage extends ConsumerStatefulWidget {
  const PermintaanSuratPage({super.key});

  @override
  ConsumerState<PermintaanSuratPage> createState() =>
      _PermintaanSuratPageState();
}

class _PermintaanSuratPageState extends ConsumerState<PermintaanSuratPage> {
  TicketStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketStreamProvider);
    final wargaAsync = ref.watch(wargaListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Permintaan Surat')),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Permintaan belum bisa dimuat',
          message: '$error',
        ),
        data: (tickets) {
          final counts = <TicketStatus, int>{
            for (final status in TicketStatus.values)
              status: tickets.where((ticket) => ticket.status == status).length,
          };
          final wargaById = wargaAsync.valueOrNull == null
              ? <String, WargaInduk>{}
              : {
                  for (final warga in wargaAsync.valueOrNull!) warga.id: warga,
                };
          final visible = tickets
              .where(
                (ticket) => _filter == null || ticket.status == _filter,
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Semua ${tickets.length}'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    for (final status in TicketStatus.values) ...[
                      ChoiceChip(
                        label:
                            Text('${_statusLabel(status)} ${counts[status]}'),
                        selected: _filter == status,
                        onSelected: (_) => setState(() => _filter = status),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'Tidak ada permintaan',
                        message:
                            'Permintaan warga akan masuk realtime di halaman ini.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(ticketStreamProvider);
                          ref.invalidate(wargaListProvider);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) => _AdminTicketCard(
                            ticket: visible[index],
                            warga: wargaById[visible[index].wargaId],
                          ),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemCount: visible.length,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(TicketStatus status) {
    return switch (status) {
      TicketStatus.baru => 'Baru',
      TicketStatus.diproses => 'Proses',
      TicketStatus.selesai => 'Selesai',
      TicketStatus.complete => 'Complete',
      TicketStatus.pending => 'Pending',
      TicketStatus.batal => 'Batal',
    };
  }
}

class _AdminTicketCard extends ConsumerWidget {
  const _AdminTicketCard({required this.ticket, required this.warga});

  final TicketRequest ticket;
  final WargaInduk? warga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = _nextStatuses(ticket.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              warga?.namaLengkap ?? ticket.wargaId,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (warga != null)
              Text(
                'NIK ${warga!.nik} • KK ${warga!.nomorKk}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
              Text('Tanggal ambil: ${AppFormatters.date(ticket.pickupDate!)}'),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in actions.take(1))
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _changeStatus(context, ref, status),
                        child: Text('${_actionLabel(status)} ->'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TicketStatus> _nextStatuses(TicketStatus current) {
    return switch (current) {
      TicketStatus.baru => [TicketStatus.diproses, TicketStatus.batal],
      TicketStatus.diproses => [TicketStatus.selesai, TicketStatus.batal],
      TicketStatus.selesai => [TicketStatus.complete, TicketStatus.pending],
      TicketStatus.pending => [TicketStatus.complete],
      TicketStatus.complete || TicketStatus.batal => const [],
    };
  }

  String _actionLabel(TicketStatus status) {
    return switch (status) {
      TicketStatus.diproses => 'Proses',
      TicketStatus.selesai => 'Berkas Siap',
      TicketStatus.complete => 'Konfirmasi Ambil',
      TicketStatus.pending => 'Pending',
      TicketStatus.batal => 'Batalkan',
      TicketStatus.baru => 'Baru',
    };
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    TicketStatus status,
  ) async {
    try {
      await ref.read(ticketRepositoryProvider).updateStatus(ticket.id, status);
      if (status == TicketStatus.selesai) {
        await ref.read(notificationRepositoryProvider).create(
              AppNotification(
                id: '',
                wargaId: ticket.wargaId,
                ticketId: ticket.id,
                type: 'TICKET_SELESAI',
                title: 'Berkas siap diambil',
                body: 'Surat ${ticket.jenisKeperluan} sudah selesai diproses.',
                createdAt: DateTime.now(),
              ),
            );
      }
      ref.invalidate(ticketStreamProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status diubah ke ${status.dbValue}.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah status: $e')));
    }
  }
}
