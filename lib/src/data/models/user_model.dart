
import 'package:flutter/foundation.dart';

enum UserRole { admin, employee }

@immutable
class UserModel {
  final String id;
  final String username;
  final String hashedPassword;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.username,
    required this.hashedPassword,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'hashedPassword': hashedPassword,
      'role': role.name, // Simpan nama enum sebagai string (e.g., 'admin')
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String,
      hashedPassword: map['hashedPassword'] as String,
      role: UserRole.values.byName(map['role'] as String), // Ambil enum dari nama string
    );
  }
}
