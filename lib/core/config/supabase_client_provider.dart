import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Inisialisasi Supabase sekali di `main.dart`:
///   await SupabaseInit.initialize();
///
/// Setelah itu, akses client di mana saja lewat `SupabaseInit.client`
/// atau (lebih disarankan) lewat provider Riverpod di
/// `data/datasources/supabase_datasource.dart`.
class SupabaseInit {
  SupabaseInit._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
      // debug: true, // aktifkan saat development untuk melihat log request
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
