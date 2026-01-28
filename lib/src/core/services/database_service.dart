
import 'dart:convert';
import 'dart:io'; // New import for File operations
import 'package:crypto/crypto.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart'; // New import for permission_handler

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDB();
    return _database!;
  }

  Future<String> get fullPath async {
    const name = 'kasir_app.db';
    final path = await getDatabasesPath();
    return join(path, name);
  }

  Future<Database> _initializeDB() async {
    final path = await fullPath;
    return await openDatabase(
      path,
      version: 4, // Versi database ditingkatkan
      onCreate: (database, version) async {
        await database.execute(
          """
          CREATE TABLE products(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            cost REAL NOT NULL DEFAULT 0.0,
            category TEXT,
            image_url TEXT,
            stock INTEGER NOT NULL DEFAULT 0
          )
          """,
        );
        await database.execute(
          """
          CREATE TABLE transactions(
            id TEXT PRIMARY KEY,
            items TEXT NOT NULL,
            total_amount REAL NOT NULL,
            payment_method TEXT NOT NULL,
            amount_paid REAL NOT NULL DEFAULT 0.0,
            change REAL NOT NULL DEFAULT 0.0,
            cashier_id TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
          """,
        );
        await database.execute(
          """
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            hashedPassword TEXT NOT NULL,
            role TEXT NOT NULL
          )
          """,
        );
        await _createDefaultAdmin(database);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE products ADD COLUMN cost REAL NOT NULL DEFAULT 0.0;");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE transactions ADD COLUMN amount_paid REAL NOT NULL DEFAULT 0.0;");
          await db.execute("ALTER TABLE transactions ADD COLUMN change REAL NOT NULL DEFAULT 0.0;");
        }
        if (oldVersion < 4) {
          await db.execute("ALTER TABLE products ADD COLUMN stock INTEGER NOT NULL DEFAULT 0;");
        }
      },
    );
  }

  Future<void> _createDefaultAdmin(Database db) async {
    final List<Map<String, dynamic>> users = await db.query('users');
    if (users.isEmpty) {
      final defaultAdmin = UserModel(
        id: const Uuid().v4(),
        username: 'admin',
        hashedPassword: sha256.convert(utf8.encode('admin')).toString(),
        role: UserRole.admin,
      );
      await db.insert('users', defaultAdmin.toMap());
    }
  }

  /// Backup the database to a specified destination.
  Future<void> backupDatabase(String destinationPath) async {
    final currentDbPath = await fullPath;
    final backupFile = File(destinationPath);
    final currentDbFile = File(currentDbPath);

    if (await currentDbFile.exists()) {
      // Ensure the destination directory exists
      await backupFile.parent.create(recursive: true);
      await currentDbFile.copy(backupFile.path);
      print('Database backed up to: $destinationPath');
    } else {
      print('Original database file not found at: $currentDbPath');
      throw Exception('Original database file not found.');
    }
  }

  /// Restore the database from a specified backup file.
  Future<void> restoreDatabase(String backupFilePath) async {
    final currentDbPath = await fullPath;
    final backupFile = File(backupFilePath);
    final currentDbFile = File(currentDbPath);

    if (!await backupFile.exists()) {
      print('Backup file not found at: $backupFilePath');
      throw Exception('Backup file not found.');
    }

    // Close the existing database connection if open
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null; // Set to null to force re-initialization
    }

    // Delete the existing database file
    if (await currentDbFile.exists()) {
      await currentDbFile.delete();
    }

    // Copy the backup file to the database location
    await backupFile.copy(currentDbPath);
    print('Database restored from: $backupFilePath');

    // Re-initialize the database
    _database = await _initializeDB();
  }
}
