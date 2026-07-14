import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/router/app_router.dart';
import '../../data/repositories/repository_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Beri sedikit delay untuk menampilkan logo, lalu cek session.
    Future.delayed(const Duration(milliseconds: 800), _resolveInitialRoute);
  }

  Future<void> _resolveInitialRoute() async {
    final authRepo = ref.read(authRepositoryProvider);

    if (!authRepo.isLoggedIn) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    try {
      final profile = await authRepo.getMyProfile();
      if (!mounted) return;

      switch (profile.role) {
        case UserRole.warga:
          context.go(AppRoutes.wargaHome);
        case UserRole.admin:
        case UserRole.superAdmin:
          context.go(AppRoutes.adminHome);
      }
    } catch (_) {
      // Profile gagal dimuat (mis. token invalid) -> paksa login ulang.
      await authRepo.logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('assets/images/rukun_kita_logo_512.png'),
              width: 128,
              height: 128,
            ),
            SizedBox(height: 24),
            Text(
              'Rukun Kita',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
