
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/database_service.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:sqflite/sqflite.dart';

class TransactionRepository {
  final DatabaseService _databaseService = getIt<DatabaseService>();

  // Mengambil transaksi dalam rentang tanggal tertentu
  Future<List<TransactionModel>> getTransactionsInRange(DateTime startTime, DateTime endTime) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [startTime.toIso8601String(), endTime.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  // Menambah transaksi baru dan mengurangi stok produk
  Future<void> addTransaction(TransactionModel transaction) async {
    final db = await _databaseService.database;

    await db.transaction((txn) async {
      // 1. Masukkan data transaksi ke tabel 'transactions'
      await txn.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Perbarui stok untuk setiap produk yang ada di dalam transaksi
      for (var item in transaction.items) {
        // Ambil stok saat ini terlebih dahulu untuk memastikan tidak minus
        final currentStockResult = await txn.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [item.product.id],
        );

        if (currentStockResult.isNotEmpty) {
          final currentStock = currentStockResult.first['stock'] as int;
          final newStock = currentStock - item.quantity;

          await txn.update(
            'products',
            {'stock': newStock > 0 ? newStock : 0}, // Pastikan stok tidak menjadi negatif
            where: 'id = ?',
            whereArgs: [item.product.id],
          );
        }
      }
    });
  }
}
