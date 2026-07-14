import '../datasources/supabase_datasource.dart';

class WargaLoginAccount {
  const WargaLoginAccount({
    required this.wargaId,
    this.profileId,
    this.username,
    this.email,
    this.role,
    this.createdAuthUser = false,
  });

  final String wargaId;
  final String? profileId;
  final String? username;
  final String? email;
  final String? role;
  final bool createdAuthUser;

  bool get isLinked => profileId != null;

  factory WargaLoginAccount.fromJson(Map<String, dynamic> json) {
    return WargaLoginAccount(
      wargaId: json['warga_id'] as String,
      profileId: json['profile_id'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      createdAuthUser: json['created_auth_user'] as bool? ?? false,
    );
  }
}

class WargaAccountRepository extends SupabaseDatasource {
  WargaAccountRepository(super.client);

  Future<WargaLoginAccount> getForWarga(String wargaId) async {
    final response = await client.functions.invoke(
      'admin-warga-login',
      body: {
        'action': 'get',
        'warga_id': wargaId,
      },
    );
    return WargaLoginAccount.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<WargaLoginAccount> upsertForWarga({
    required String wargaId,
    required String login,
    String? kodeAkses,
  }) async {
    final response = await client.functions.invoke(
      'admin-warga-login',
      body: {
        'action': 'upsert',
        'warga_id': wargaId,
        'login': login,
        if (kodeAkses != null && kodeAkses.isNotEmpty) 'kode_akses': kodeAkses,
      },
    );
    return WargaLoginAccount.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
