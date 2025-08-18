
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/database_service.dart';
import 'package:kasir_app/src/data/models/user_model.dart';

class AuthRepository {
  final DatabaseService _databaseService = getIt<DatabaseService>();

  /// Attempts to log in a user with the given username and password.
  /// Returns a [UserModel] if successful, otherwise returns `null`.
  Future<UserModel?> login(String username, String password) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      final user = UserModel.fromMap(maps.first);
      final providedPasswordHash = sha256.convert(utf8.encode(password)).toString();

      // Compare the hashed passwords
      if (user.hashedPassword == providedPasswordHash) {
        return user;
      }
    }
    // Return null if user not found or password doesn't match
    return null;
  }

  // Di masa depan, kita bisa tambahkan fungsi lain seperti:
    Future<void> logout() async {
    // Implementasi logout: Hapus token, sesi, atau data pengguna yang tersimpan
    // Contoh: await _secureStorage.delete(key: 'user_token');
    // Untuk saat ini, kita hanya mengembalikan Future yang selesai
    return Future.value();
  }
  // Future<UserModel?> getCurrentUser() async { ... }
}
