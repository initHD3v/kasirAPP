
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/database_service.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:sqflite/sqflite.dart';

class ProductRepository {
  final DatabaseService _databaseService = getIt<DatabaseService>();

  // Mengambil semua produk, dengan opsi filter pencarian berdasarkan nama
  Future<List<Product>> getProducts({String? query}) async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.isNotEmpty) {
      maps = await db.query(
        'products',
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
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
}
