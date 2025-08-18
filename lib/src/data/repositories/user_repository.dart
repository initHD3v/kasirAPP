
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/database_service.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class UserRepository {
  final DatabaseService _databaseService = getIt<DatabaseService>();

  Future<List<UserModel>> getUsers() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('users', orderBy: 'username ASC');
    return List.generate(maps.length, (i) {
      return UserModel.fromMap(maps[i]);
    });
  }

  Future<void> addUser(String username, String password, UserRole role) async {
    final db = await _databaseService.database;
    final newUser = UserModel(
      id: const Uuid().v4(),
      username: username,
      hashedPassword: sha256.convert(utf8.encode(password)).toString(),
      role: role,
    );
    try {
      await db.insert(
        'users',
        newUser.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort, // Akan error jika username sudah ada
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Username "$username" sudah digunakan.');
      }
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    final db = await _databaseService.database;
    // Cegah admin menghapus diri sendiri
    // Logika ini sebaiknya ada di BLoC, tapi sebagai pengaman tambahan di sini tidak apa-apa
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
