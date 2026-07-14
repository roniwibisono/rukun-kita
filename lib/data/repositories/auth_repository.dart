import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/constants/table_names.dart';
import '../datasources/supabase_datasource.dart';
import '../models/profile.dart';

/// Menangani login/logout serta resolusi role user yang sedang aktif.
///
/// PENTING (lihat PRD §4): DB memakai `profiles.username`, sedangkan
/// Supabase Auth native butuh email/phone. Kita jembatani dengan pseudo-email
/// `"{username}@{AUTH_PSEUDO_EMAIL_DOMAIN}"`. Layar login tetap hanya
/// menampilkan field Username + Kode Akses ke user.
class AuthRepository extends SupabaseDatasource {
  AuthRepository(super.client);

  String _toAuthEmail(String username) {
    final normalized = username.trim().toLowerCase();
    if (normalized.contains('@')) return normalized;
    return '$normalized@${Env.authPseudoEmailDomain}';
  }

  /// Login dengan username + kode akses (kode akses = password Supabase Auth).
  Future<Profile> login({
    required String username,
    required String kodeAkses,
  }) async {
    final response = await auth.signInWithPassword(
      email: _toAuthEmail(username),
      password: kodeAkses,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException(
        'Login gagal — periksa kembali username dan kode akses.',
      );
    }

    return getMyProfile();
  }

  Future<void> logout() => auth.signOut();

  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  /// Ambil profile milik user yang sedang login (untuk cek role).
  Future<Profile> getMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) {
      throw StateError('Tidak ada user yang sedang login.');
    }

    final row =
        await client.from(TableNames.profiles).select().eq('id', uid).single();

    return Profile.fromJson(row);
  }
}
