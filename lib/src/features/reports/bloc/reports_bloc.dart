import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';

part 'reports_event.dart';
part 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final TransactionRepository _transactionRepository;

  ReportsBloc(this._transactionRepository) : super(ReportsInitial()) {
    on<LoadReports>(_onLoadReports);
    on<DeleteAllTransactions>(_onDeleteAllTransactions);
  }

  void _onLoadReports(LoadReports event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    try {
      final transactions = await _transactionRepository.getTransactionsInRange(
        event.startTime,
        event.endTime,
      );

      final double totalRevenue = transactions.fold(0, (sum, tx) => sum + tx.totalAmount);
      final double totalCostOfGoodsSold = transactions.fold(0, (sum, tx) => sum + tx.items.fold(0, (itemSum, item) => itemSum + item.totalCost));
      final double grossProfit = totalRevenue - totalCostOfGoodsSold;

      // --- Logika untuk memproses data grafik ---
      final Map<String, double> dailyRevenue = {};
      final DateFormat formatter = (event.endTime.difference(event.startTime).inDays < 8)
          ? DateFormat('E') // Format hari (Sen, Sel, ...)
          : DateFormat('dd/MM'); // Format tanggal (23/08)

      for (var tx in transactions) {
        final day = formatter.format(tx.createdAt);
        dailyRevenue[day] = (dailyRevenue[day] ?? 0) + tx.totalAmount;
      }

      final chartData = dailyRevenue.entries
          .map((entry) => ChartData(label: entry.key, value: entry.value))
          .toList()
          .reversed // Balik urutan agar hari terlama di kiri
          .toList();
      // -- Selesai --

      // --- Logika untuk produk terlaris ---
      final Map<String, ProductSalesData> productSalesMap = {};
      for (var tx in transactions) {
        for (var item in tx.items) {
          final productId = item.product.id;
          final productName = item.product.name;
          final quantity = item.quantity;
          final revenue = item.product.price * item.quantity;

          if (productSalesMap.containsKey(productId)) {
            final existingData = productSalesMap[productId]!;
            productSalesMap[productId] = ProductSalesData(
              productId: productId,
              productName: productName,
              totalQuantitySold: existingData.totalQuantitySold + quantity,
              totalRevenueGenerated: existingData.totalRevenueGenerated + revenue,
            );
          } else {
            productSalesMap[productId] = ProductSalesData(
              productId: productId,
              productName: productName,
              totalQuantitySold: quantity,
              totalRevenueGenerated: revenue,
            );
          }
        }
      }
      final bestSellingProducts = productSalesMap.values.toList()
        ..sort((a, b) => b.totalQuantitySold.compareTo(a.totalQuantitySold)); // Urutkan berdasarkan jumlah terjual
      // -- Selesai --

      emit(ReportsLoaded(
        transactions: transactions,
        totalRevenue: totalRevenue,
        totalCostOfGoodsSold: totalCostOfGoodsSold,
        grossProfit: grossProfit,
        chartData: chartData,
        bestSellingProducts: bestSellingProducts,
      ));
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  void _onDeleteAllTransactions(DeleteAllTransactions event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading()); // Or a specific DeletingReports state
    try {
      await _transactionRepository.deleteAllTransactions();
      // After deletion, reload the reports to show an empty list or updated data
      add(LoadReports(startTime: DateTime.now().subtract(const Duration(days: 30)), endTime: DateTime.now())); // Reload for a month
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  
}