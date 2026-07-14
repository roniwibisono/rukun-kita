import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/repository_providers.dart';
import '../../features/admin/buku_administrasi/admin_buku_administrasi_page.dart';
import '../../features/admin/data_warga/data_warga_page.dart';
import '../../features/admin/home/admin_home_page.dart';
import '../../features/admin/permintaan_surat/permintaan_surat_page.dart';
import '../../features/admin/retribusi_iuran/retribusi_iuran_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/warga/ajukan_surat/ajukan_surat_page.dart';
import '../../features/warga/buku_administrasi/warga_buku_administrasi_page.dart';
import '../../features/warga/home/warga_home_page.dart';
import '../../features/warga/notifikasi/notifikasi_page.dart';
import '../../features/warga/profil_keluarga/profil_keluarga_page.dart';
import '../../features/warga/riwayat_permintaan/riwayat_permintaan_page.dart';
import '../constants/enums.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const wargaHome = '/warga';
  static const wargaAjukanSurat = '/warga/ajukan-surat';
  static const wargaRiwayatPermintaan = '/warga/riwayat-permintaan';
  static const wargaBukuAdministrasi = '/warga/buku-administrasi';
  static const wargaNotifikasi = '/warga/notifikasi';
  static const wargaProfilKeluarga = '/warga/profil-keluarga';
  static const adminHome = '/admin';
  static const adminPermintaanSurat = '/admin/permintaan-surat';
  static const adminRetribusiIuran = '/admin/retribusi-iuran';
  static const adminDataWarga = '/admin/data-warga';
  static const adminBukuAdministrasi = '/admin/buku-administrasi';
}

/// Router utama app. Redirect logic:
///   - Belum ada session         -> /login (kecuali sedang di /splash)
///   - Ada session, role WARGA   -> /warga
///   - Ada session, role ADMIN/SUPER_ADMIN -> /admin
///
/// AI agent: tambahkan sub-route (mis. `/warga/ajukan-surat`,
/// `/admin/permintaan-surat/:id`) sesuai kebutuhan fitur di PRD §5.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.wargaHome,
        builder: (context, state) => const WargaHomePage(),
      ),
      GoRoute(
        path: AppRoutes.wargaAjukanSurat,
        builder: (context, state) => const AjukanSuratPage(),
      ),
      GoRoute(
        path: AppRoutes.wargaRiwayatPermintaan,
        builder: (context, state) => const RiwayatPermintaanPage(),
      ),
      GoRoute(
        path: AppRoutes.wargaBukuAdministrasi,
        builder: (context, state) => const WargaBukuAdministrasiPage(),
      ),
      GoRoute(
        path: AppRoutes.wargaNotifikasi,
        builder: (context, state) => const NotifikasiPage(),
      ),
      GoRoute(
        path: AppRoutes.wargaProfilKeluarga,
        builder: (context, state) => const ProfilKeluargaPage(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminHomePage(),
      ),
      GoRoute(
        path: AppRoutes.adminPermintaanSurat,
        builder: (context, state) => const PermintaanSuratPage(),
      ),
      GoRoute(
        path: AppRoutes.adminRetribusiIuran,
        builder: (context, state) => const RetribusiIuranPage(),
      ),
      GoRoute(
        path: AppRoutes.adminDataWarga,
        builder: (context, state) => const DataWargaPage(),
      ),
      GoRoute(
        path: AppRoutes.adminBukuAdministrasi,
        builder: (context, state) => const AdminBukuAdministrasiPage(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = ref.read(authRepositoryProvider).isLoggedIn;
      final goingToSplash = state.matchedLocation == AppRoutes.splash;
      final goingToLogin = state.matchedLocation == AppRoutes.login;

      if (goingToSplash) return null; // biarkan splash urus pengecekan awal

      if (!isLoggedIn) {
        return goingToLogin ? null : AppRoutes.login;
      }

      // Sudah login — jangan biarkan tetap di /login
      if (goingToLogin) {
        return _redirectPathForRole(ref);
      }

      return null;
    },
  );
});

String _redirectPathForRole(Ref ref) {
  final profileAsync = ref.read(currentProfileProvider);
  final profile = profileAsync.valueOrNull;

  if (profile == null) {
    return AppRoutes.splash; // profile belum siap, tunggu splash reload
  }

  switch (profile.role) {
    case UserRole.warga:
      return AppRoutes.wargaHome;
    case UserRole.admin:
    case UserRole.superAdmin:
      return AppRoutes.adminHome;
  }
}
