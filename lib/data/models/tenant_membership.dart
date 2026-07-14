import '../../core/constants/enums.dart';

/// Mirror tabel `public.tenant_memberships`.
class TenantMembership {
  const TenantMembership({
    required this.id,
    required this.tenantId,
    required this.profileId,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String tenantId;
  final String profileId;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  factory TenantMembership.fromJson(Map<String, dynamic> json) =>
      TenantMembership(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        profileId: json['profile_id'] as String,
        role: UserRole.fromDb(json['role'] as String),
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
