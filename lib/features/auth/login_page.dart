import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/enums.dart';
import '../../core/router/app_router.dart';
import '../../data/repositories/repository_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _kodeAksesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _kodeAksesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await ref.read(authRepositoryProvider).login(
            username: _usernameController.text.trim(),
            kodeAkses: _kodeAksesController.text,
          );

      if (!mounted) return;

      switch (profile.role) {
        case UserRole.warga:
          context.go(AppRoutes.wargaHome);
        case UserRole.admin:
        case UserRole.superAdmin:
          context.go(AppRoutes.adminHome);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = _friendlyLoginError(e.message));
    } catch (e) {
      setState(() => _errorMessage = _friendlyLoginError('$e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyLoginError(String error) {
    final normalized = error.toLowerCase();
    if (normalized.contains('failed host lookup') ||
        normalized.contains('clientexception') ||
        normalized.contains('socketexception') ||
        normalized.contains('no address associated with hostname') ||
        normalized.contains('connection failed') ||
        normalized.contains('network is unreachable')) {
      return 'Tidak bisa menemukan server Rukun Kita. Periksa koneksi internet, matikan VPN/Private DNS jika aktif, lalu coba lagi.';
    }
    if (normalized.contains('invalid login credentials')) {
      return 'Username/email atau kode akses tidak sesuai.';
    }
    if (normalized.contains('timeout') || normalized.contains('timed out')) {
      return 'Koneksi ke server terlalu lama. Coba lagi beberapa saat.';
    }
    return 'Login gagal. Periksa data masuk atau coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Selamat Datang di Rukun Kita',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masuk dengan username dan kode akses yang diberikan pengurus RT.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Username wajib diisi'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kodeAksesController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kode Akses',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Kode akses wajib diisi'
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
