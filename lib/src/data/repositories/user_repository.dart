
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
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateUser(UserModel user, {String? newPassword}) async {
    final db = await _databaseService.database;
    String hashedPassword = user.hashedPassword; // Start with the existing hashed password

    // If a new password is provided, hash it
    if (newPassword != null && newPassword.isNotEmpty) {
      hashedPassword = sha256.convert(utf8.encode(newPassword)).toString();
    }
    
    final updatedUserMap = user.toMap();
    updatedUserMap['hashedPassword'] = hashedPassword; // Ensure hashed password is used

    await db.update(
      'users',
      updatedUserMap,
      where: 'id = ?',
      whereArgs: [user.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }
}
