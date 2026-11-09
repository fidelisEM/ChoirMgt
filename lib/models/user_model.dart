enum UserRole { superAdmin, admin, choirLeader, choirMember }

class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
    this.profileImageUrl,
    this.suggestedChoir = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.toString().split('.').last == json['role'],
        orElse: () => UserRole.choirMember,
      ),
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      lastLogin: (json['last_login'] ?? json['lastLogin']) != null
          ? DateTime.parse(json['last_login'] ?? json['lastLogin'])
          : null,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      profileImageUrl: json['profile_image_url'] ?? json['profileImageUrl'],
      suggestedChoir: json['suggested_choir'] ?? json['suggestedChoir'] ?? '',
    );
  }
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final String? profileImageUrl;
  final String suggestedChoir;

  // Super Admin sits above Admin in the role hierarchy, so anywhere an
  // Admin has access, a Super Admin must too - use this instead of
  // `role == UserRole.admin` for any "is this user an admin" check.
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive,
      'profile_image_url': profileImageUrl,
      // 'suggested_choir': suggestedChoir, // Commented out - column doesn't exist in database
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    String? profileImageUrl,
    String? suggestedChoir,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      suggestedChoir: suggestedChoir ?? this.suggestedChoir,
    );
  }
}
