import '../../core/constants/enums.dart';

/// Mirror tabel `public.profiles`.
class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.role,
    required this.createdAt,
  });

  final String id; // = auth.users.id
  final String username;
  final UserRole role;
  final DateTime createdAt;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        username: json['username'] as String,
        role: UserRole.fromDb(json['role'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role.dbValue,
      };

  Profile copyWith({String? username, UserRole? role}) => Profile(
        id: id,
        username: username ?? this.username,
        role: role ?? this.role,
        createdAt: createdAt,
      );
}
