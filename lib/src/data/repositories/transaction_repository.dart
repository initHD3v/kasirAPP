import 'package:intl/intl.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/database_service.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:kasir_app/src/features/dashboard/bloc/dashboard_bloc.dart';
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

  Future<Map<String, dynamic>> getDashboardData() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    // 1. Get transactions for today and the last 7 days
    final todayTransactions = await getTransactionsInRange(todayStart, todayEnd);
    final weeklyTransactions = await getTransactionsInRange(weekStart, todayEnd);

    // 2. Calculate Today's KPIs
    final double totalRevenueToday = todayTransactions.fold(0, (sum, tx) => sum + tx.totalAmount);
    final int transactionCountToday = todayTransactions.length;

    // 3. Process weekly sales chart data
    final Map<String, double> dailyRevenue = {};
    final DateFormat formatter = DateFormat('E', 'id_ID'); // 'E' gives day of week name (Sen, Sel, ...)
    for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        dailyRevenue[formatter.format(day)] = 0.0;
    }
    for (var tx in weeklyTransactions) {
      final day = formatter.format(tx.createdAt);
      dailyRevenue[day] = (dailyRevenue[day] ?? 0) + tx.totalAmount;
    }
    final weeklySales = dailyRevenue.entries
        .map((entry) => DashboardChartData(label: entry.key, value: entry.value))
        .toList();
    
    // 4. Process top selling products (from today's transactions)
    final Map<String, int> productSalesMap = {};
    for (var tx in todayTransactions) {
      for (var item in tx.items) {
        productSalesMap[item.product.name] = (productSalesMap[item.product.name] ?? 0) + item.quantity;
      }
    }
    final topProducts = productSalesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top5Products = topProducts.take(5).map((e) => DashboardTopProduct(name: e.key, quantity: e.value)).toList();


    return {
      'totalRevenueToday': totalRevenueToday,
      'transactionCountToday': transactionCountToday,
      'weeklySales': weeklySales,
      'topProducts': top5Products,
    };
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

  Future<void> deleteAllTransactions() async {
    final db = await _databaseService.database;
    await db.delete('transactions');
  }
}
