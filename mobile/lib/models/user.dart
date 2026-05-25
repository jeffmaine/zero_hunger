import '../core/json_parse.dart';
import 'enums.dart';

class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.latitude,
    this.longitude,
    this.locationLabel,
    this.avatarUrl,
    this.organizationName,
    this.bio,
    this.isVerified = false,
    this.authProvider = 'manual',
    this.mealsShared = 0,
    this.successfulPickups = 0,
    this.claimNoShows = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String phone;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final String? avatarUrl;
  final String? organizationName;
  final String? bio;
  final bool isVerified;
  final String authProvider;
  final int mealsShared;
  final int successfulPickups;
  final int claimNoShows;
  final DateTime createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'receiver';
    final stats = json['stats'] as Map<String, dynamic>?;
    return UserModel(
      id: parseUuid(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.values.byName(roleStr),
      phone: json['phone'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationLabel: json['location_label'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      organizationName: json['organization_name'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      authProvider: json['auth_provider'] as String? ?? 'manual',
      mealsShared: stats != null ? parseInt(stats['meals_shared']) : 0,
      successfulPickups: stats != null ? parseInt(stats['successful_pickups']) : 0,
      claimNoShows: stats != null ? parseInt(stats['claim_no_shows']) : 0,
      createdAt: json['created_at'] != null ? parseDateTime(json['created_at']) : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? locationLabel,
    String? avatarUrl,
    String? organizationName,
    String? bio,
    double? latitude,
    double? longitude,
    int? mealsShared,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      organizationName: organizationName ?? this.organizationName,
      bio: bio ?? this.bio,
      isVerified: isVerified,
      authProvider: authProvider,
      mealsShared: mealsShared ?? this.mealsShared,
      createdAt: createdAt,
    );
  }
}
