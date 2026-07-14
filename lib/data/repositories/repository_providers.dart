import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_client_provider.dart';
import 'auth_repository.dart';
import 'buku_administrasi_repository.dart';
import 'iuran_edit_request_repository.dart';
import 'iuran_repository.dart';
import 'notification_repository.dart';
import 'ticket_repository.dart';
import 'warga_account_repository.dart';
import 'warga_repository.dart';

/// Satu provider client Supabase, dipakai semua repository di bawahnya.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseInit.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final wargaRepositoryProvider = Provider<WargaRepository>((ref) {
  return WargaRepository(ref.watch(supabaseClientProvider));
});

final wargaAccountRepositoryProvider = Provider<WargaAccountRepository>((ref) {
  return WargaAccountRepository(ref.watch(supabaseClientProvider));
});

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(ref.watch(supabaseClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

final iuranRepositoryProvider = Provider<IuranRepository>((ref) {
  return IuranRepository(ref.watch(supabaseClientProvider));
});

final iuranEditRequestRepositoryProvider =
    Provider<IuranEditRequestRepository>((ref) {
  return IuranEditRequestRepository(ref.watch(supabaseClientProvider));
});

// --- Buku administrasi (generic CRUD) ---

final suratMasukRepositoryProvider = Provider<SuratMasukRepository>((ref) {
  return SuratMasukRepository(ref.watch(supabaseClientProvider));
});

final suratKeluarRepositoryProvider = Provider<SuratKeluarRepository>((ref) {
  return SuratKeluarRepository(ref.watch(supabaseClientProvider));
});

final bukuEkspedisiRepositoryProvider = Provider<BukuEkspedisiRepository>((
  ref,
) {
  return BukuEkspedisiRepository(ref.watch(supabaseClientProvider));
});

final kasUmumRepositoryProvider = Provider<KasUmumRepository>((ref) {
  return KasUmumRepository(ref.watch(supabaseClientProvider));
});

final bukuTamuRepositoryProvider = Provider<BukuTamuRepository>((ref) {
  return BukuTamuRepository(ref.watch(supabaseClientProvider));
});

final inventarisRtRepositoryProvider = Provider<InventarisRtRepository>((ref) {
  return InventarisRtRepository(ref.watch(supabaseClientProvider));
});

final notulenRapatRepositoryProvider = Provider<NotulenRapatRepository>((ref) {
  return NotulenRapatRepository(ref.watch(supabaseClientProvider));
});

final presensiRapatRepositoryProvider = Provider<PresensiRapatRepository>((
  ref,
) {
  return PresensiRapatRepository(ref.watch(supabaseClientProvider));
});

final pengurusRtRepositoryProvider = Provider<PengurusRtRepository>((ref) {
  return PengurusRtRepository(ref.watch(supabaseClientProvider));
});

final wargaMutasiRepositoryProvider = Provider<WargaMutasiRepository>((ref) {
  return WargaMutasiRepository(ref.watch(supabaseClientProvider));
});

final wargaSementaraRepositoryProvider = Provider<WargaSementaraRepository>((
  ref,
) {
  return WargaSementaraRepository(ref.watch(supabaseClientProvider));
});

/// Auth state stream — dipakai `go_router` untuk redirect otomatis
/// (lihat `core/router/app_router.dart`).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Profile milik user yang sedang login (berisi role) — di-refresh
/// setiap kali authState berubah.
final currentProfileProvider = FutureProvider((ref) async {
  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState?.session == null) return null;
  return ref.watch(authRepositoryProvider).getMyProfile();
});
