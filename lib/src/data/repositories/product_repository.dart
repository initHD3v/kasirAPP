
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/database_service.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:sqflite/sqflite.dart';

class ProductRepository {
  final DatabaseService _databaseService = getIt<DatabaseService>();

  // Mengambil semua produk, dengan opsi filter pencarian berdasarkan nama dan/atau kategori
  Future<List<Product>> getProducts({String? query, String? category}) async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClause += 'name LIKE ?';
      whereArgs.add('%$query%');
    }

    if (category != null && category.isNotEmpty) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'category = ?';
      whereArgs.add(category);
    }
    
    if (whereClause.isNotEmpty) {
      maps = await db.query(
        'products',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query('products', orderBy: 'name ASC');
    }

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Menambah produk baru
  Future<void> insertProduct(Product product) async {
    final db = await _databaseService.database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Memperbarui produk
  Future<void> updateProduct(Product product) async {
    final db = await _databaseService.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Menghapus produk
  Future<void> deleteProduct(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mengambil daftar kategori unik dari semua produk yang tersedia.
  Future<List<String>> getUniqueCategories() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      columns: ['DISTINCT category'],
      where: 'category IS NOT NULL AND category != ?', // Filter out nulls and empty strings
      whereArgs: [''],
    );
    return maps.map((map) => map['category'] as String).toList();
  }
}
