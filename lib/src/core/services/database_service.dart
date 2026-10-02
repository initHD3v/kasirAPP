
import 'dart:convert';
import 'dart:io'; // New import for File operations
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
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
      version: 5, // Versi database ditingkatkan untuk kolom 'category' pada produk
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
        await _seedDemoProducts(database);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        Future<void> addColumnIfMissing(
          String table,
          String column,
          String ddl,
        ) async {
          final info = await db.rawQuery('PRAGMA table_info($table)');
          final exists = info.any((c) => c['name'] == column);
          if (!exists) {
            await db.execute('ALTER TABLE $table ADD COLUMN $ddl;');
          }
        }

        if (oldVersion < 2) {
          await addColumnIfMissing(
            'products',
            'cost',
            'cost REAL NOT NULL DEFAULT 0.0',
          );
        }
        if (oldVersion < 3) {
          await addColumnIfMissing(
            'transactions',
            'amount_paid',
            'amount_paid REAL NOT NULL DEFAULT 0.0',
          );
          await addColumnIfMissing(
            'transactions',
            'change',
            'change REAL NOT NULL DEFAULT 0.0',
          );
        }
        if (oldVersion < 4) {
          await addColumnIfMissing(
            'products',
            'stock',
            'stock INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 5) {
          await addColumnIfMissing('products', 'category', 'category TEXT');
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

  /// Seed 30 produk demo (10 Makanan, 10 Minuman, 10 A la carte) lengkap
  /// dengan gambar, hanya saat tabel produk masih kosong (install fresh).
  Future<void> _seedDemoProducts(Database db) async {
    final existing = await db.rawQuery('SELECT COUNT(*) AS c FROM products');
    if ((existing.first['c'] as int) > 0) return;

    const demo = [
      // Makanan: nama, harga, modal, file gambar
      ['Nasi Goreng Spesial', 18000.0, 11000.0, 'Makanan', 'makanan_01.png'],
      ['Mie Goreng Jawa', 16000.0, 9500.0, 'Makanan', 'makanan_02.png'],
      ['Ayam Goreng Lalapan', 20000.0, 12500.0, 'Makanan', 'makanan_03.png'],
      ['Nasi Ayam Bakar', 22000.0, 13500.0, 'Makanan', 'makanan_04.png'],
      ['Soto Ayam', 15000.0, 9000.0, 'Makanan', 'makanan_05.png'],
      ['Bakso Sapi', 14000.0, 8500.0, 'Makanan', 'makanan_06.png'],
      ['Mie Ayam', 13000.0, 7500.0, 'Makanan', 'makanan_07.png'],
      ['Nasi Pecel Lele', 17000.0, 10000.0, 'Makanan', 'makanan_08.png'],
      ['Rawon', 19000.0, 11500.0, 'Makanan', 'makanan_09.png'],
      ['Gado-Gado', 15000.0, 8500.0, 'Makanan', 'makanan_10.png'],
      // Minuman
      ['Es Teh Manis', 5000.0, 1500.0, 'Minuman', 'minuman_01.png'],
      ['Teh Hangat', 4000.0, 1200.0, 'Minuman', 'minuman_02.png'],
      ['Kopi Tubruk', 8000.0, 3000.0, 'Minuman', 'minuman_03.png'],
      ['Kopi Susu', 12000.0, 5000.0, 'Minuman', 'minuman_04.png'],
      ['Es Jeruk', 7000.0, 2500.0, 'Minuman', 'minuman_05.png'],
      ['Jus Alpukat', 15000.0, 7000.0, 'Minuman', 'minuman_06.png'],
      ['Jus Mangga', 14000.0, 6500.0, 'Minuman', 'minuman_07.png'],
      ['Es Cendol', 10000.0, 4000.0, 'Minuman', 'minuman_08.png'],
      ['Wedang Jahe', 8000.0, 3000.0, 'Minuman', 'minuman_09.png'],
      ['Air Mineral', 4000.0, 2000.0, 'Minuman', 'minuman_10.png'],
      // A la carte
      ['Kentang Goreng', 12000.0, 5000.0, 'A la carte', 'alacarte_01.png'],
      ['Pisang Goreng', 10000.0, 4000.0, 'A la carte', 'alacarte_02.png'],
      ['Tahu Crispy', 8000.0, 3000.0, 'A la carte', 'alacarte_03.png'],
      ['Tempe Mendoan', 8000.0, 3000.0, 'A la carte', 'alacarte_04.png'],
      ['Sate Ayam 10 Tusuk', 25000.0, 15000.0, 'A la carte', 'alacarte_05.png'],
      ['Ayam Popcorn', 15000.0, 8000.0, 'A la carte', 'alacarte_06.png'],
      ['Roti Bakar', 12000.0, 5000.0, 'A la carte', 'alacarte_07.png'],
      ['Indomie Telur Kornet', 18000.0, 10000.0, 'A la carte', 'alacarte_08.png'],
      ['Cireng', 7000.0, 2500.0, 'A la carte', 'alacarte_09.png'],
      ['Siomay', 13000.0, 6500.0, 'A la carte', 'alacarte_10.png'],
    ];

    final batch = db.batch();
    for (final p in demo) {
      String? imageBase64;
      try {
        final bytes = await rootBundle.load('assets/images/products/${p[4]}');
        imageBase64 = base64Encode(bytes.buffer.asUint8List());
      } catch (_) {
        imageBase64 = null;
      }
      batch.insert('products', {
        'id': const Uuid().v4(),
        'name': p[0],
        'price': p[1],
        'cost': p[2],
        'category': p[3],
        'image_url': imageBase64,
        'stock': 50,
      });
    }
    await batch.commit(noResult: true);
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
