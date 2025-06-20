class User {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.email,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phoneNumber: json['phone_number'],
      fullName: json['full_name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
      ),
      createdAt: DateTime.parse(json['created_at']),
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }
}

enum UserRole {
  customer,
  admin,
  manufacturer,
  thirdPartyLogistics,
  partner,
}
