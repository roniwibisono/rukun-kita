import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../shared/providers/app_data_providers.dart';
import '../../shared/widgets/empty_state.dart';

class NotifikasiPage extends ConsumerWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Notifikasi belum bisa dimuat',
          message: '$error',
        ),
        data: (notifications) {
          final sorted = [...notifications]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (sorted.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'Belum ada notifikasi',
              message: 'Kabar dari pengurus RT akan muncul di sini.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = sorted[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Icon(
                          Icons.circle,
                          size: 11,
                          color: item.isRead
                              ? Theme.of(context).disabledColor
                              : Colors.lightBlueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(item.body),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.dateTime(item.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (!item.isRead)
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(notificationRepositoryProvider)
                                .markAsRead(item.id);
                            ref.invalidate(notificationStreamProvider);
                          },
                          child: const Text('Tandai'),
                        ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: sorted.length,
          );
        },
      ),
    );
  }
}
