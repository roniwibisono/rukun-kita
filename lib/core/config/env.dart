import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Wrapper terpusat untuk semua environment variable.
/// Load sekali di `main.dart` sebelum `runApp()`:
///   await Env.load();
class Env {
  Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  static String get supabasePublishableKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? supabaseAnonKey;

  /// Domain sintetis untuk memetakan login "username + kode akses"
  /// ke email Supabase Auth. Lihat PRD §4 untuk alasan desain ini.
  static String get authPseudoEmailDomain =>
      dotenv.env['AUTH_PSEUDO_EMAIL_DOMAIN'] ?? 'rukunkita.internal';

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Environment variable "$key" tidak ditemukan. '
        'Pastikan file .env sudah dibuat dari .env.example.',
      );
    }
    return value;
  }
}
