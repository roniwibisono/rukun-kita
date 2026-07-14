import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_notification.dart';
import '../../../data/models/ticket_request.dart';
import '../../../data/models/warga_induk.dart';
import '../../../data/repositories/repository_providers.dart';

extension _AutoDisposeCache on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}

const _shortDataCache = Duration(minutes: 2);

final wargaListProvider = FutureProvider.autoDispose<List<WargaInduk>>((ref) {
  ref.cacheFor(_shortDataCache);
  return ref.watch(wargaRepositoryProvider).getAll();
});

final currentWargaProvider = FutureProvider.autoDispose<WargaInduk?>((
  ref,
) async {
  ref.cacheFor(_shortDataCache);
  final profile = await ref.watch(currentProfileProvider.future);
  final warga = await ref.watch(wargaListProvider.future);
  if (warga.isEmpty) return null;
  if (profile == null) return warga.first;

  return warga.firstWhere(
    (item) => item.profileId == profile.id,
    orElse: () => warga.first,
  );
});

final ticketStreamProvider = StreamProvider.autoDispose<List<TicketRequest>>((
  ref,
) {
  return ref.watch(ticketRepositoryProvider).watchAll();
});

final wargaTicketStreamProvider =
    StreamProvider.autoDispose<List<TicketRequest>>((ref) async* {
  final warga = await ref.watch(currentWargaProvider.future);
  if (warga == null) {
    yield const [];
    return;
  }
  yield* ref.watch(ticketRepositoryProvider).watchByWarga(warga.id);
});

final notificationStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) async* {
  final warga = await ref.watch(currentWargaProvider.future);
  if (warga == null) {
    yield const [];
    return;
  }
  yield* ref.watch(notificationRepositoryProvider).watchByWarga(warga.id);
});

final groupedWargaProvider =
    FutureProvider.autoDispose<Map<String, List<WargaInduk>>>((ref) {
  ref.cacheFor(_shortDataCache);
  return ref.watch(wargaRepositoryProvider).getGroupedByKk();
});
