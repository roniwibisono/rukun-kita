import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class untuk semua repository — menyediakan akses `SupabaseClient`
/// tanpa perlu re-inject di setiap konstruktor repository secara manual.
///
/// Semua repository sebaiknya extend class ini agar konsisten dan mudah
/// di-mock saat unit test (mock `SupabaseClient`, bukan mock tiap repo).
abstract class SupabaseDatasource {
  SupabaseDatasource(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;
  GoTrueClient get auth => _client.auth;
  RealtimeClient get realtime => _client.realtime;
  User? get currentUser => _client.auth.currentUser;
}
