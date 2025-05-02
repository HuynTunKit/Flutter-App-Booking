class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String dateOfBirth;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.dateOfBirth,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    if (uid.isEmpty) {
      throw ArgumentError('UID cannot be empty');
    }

    final email = data['email'] as String? ?? '';
    if (email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }

    final role = data['role'] as String? ?? 'user';
    if (!['user', 'admin'].contains(role)) {
      throw ArgumentError(
          'Invalid role: $role. Role must be either "user" or "admin".');
    }

    final createdAtStr = data['createdAt'] as String?;
    final updatedAtStr = data['updatedAt'] as String?;

    final createdAt = DateTime.tryParse(createdAtStr ?? '') ?? DateTime.now();
    final updatedAt = DateTime.tryParse(updatedAtStr ?? '') ?? DateTime.now();

    return UserModel(
      uid: uid,
      email: email,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      dateOfBirth: data['dateOfBirth'] as String? ?? '',
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
