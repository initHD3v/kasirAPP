

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

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
            cost REAL NOT NULL DEFAULT 0.0, -- Kolom cost ditambahkan
            category TEXT,
            image_url TEXT,
            stock INTEGER NOT NULL DEFAULT 0 -- Kolom stock ditambahkan
          )
          """,
        );
        await database.execute(
          """
          CREATE TABLE transactions(
            id TEXT PRIMARY KEY,
            items TEXT NOT NULL, -- Simpan sebagai JSON String
            total_amount REAL NOT NULL,
            payment_method TEXT NOT NULL,
            amount_paid REAL NOT NULL DEFAULT 0.0,
            change REAL NOT NULL DEFAULT 0.0,
            cashier_id TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL -- Simpan sebagai ISO 8601 String
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
        // Tambahkan user admin default
        await _createDefaultAdmin(database);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migrasi dari versi 1 ke versi 2: Tambah kolom 'cost' ke tabel 'products'
          await db.execute("ALTER TABLE products ADD COLUMN cost REAL NOT NULL DEFAULT 0.0;");
        }
        if (oldVersion < 3) {
          // Migrasi dari versi 2 ke versi 3: Tambah kolom 'amount_paid', 'change', 'cashier_id' ke tabel 'transactions'
          await db.execute("ALTER TABLE transactions ADD COLUMN amount_paid REAL NOT NULL DEFAULT 0.0;");
          await db.execute("ALTER TABLE transactions ADD COLUMN change REAL NOT NULL DEFAULT 0.0;");
          await db.execute("ALTER TABLE transactions ADD COLUMN cashier_id TEXT NOT NULL DEFAULT '';");
        }
        if (oldVersion < 4) {
          // Migrasi dari versi 3 ke versi 4: Tambah kolom 'stock' ke tabel 'products'
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
}

