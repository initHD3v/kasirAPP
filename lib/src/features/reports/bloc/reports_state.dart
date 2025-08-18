
part of 'reports_bloc.dart';

// Data class untuk setiap batang pada grafik
class ChartData {
  final String label; // Label di sumbu X (misal: nama hari atau tanggal)
  final double value; // Nilai di sumbu Y (misal: total pendapatan)

  const ChartData({required this.label, required this.value});
}

// Data class untuk produk terlaris
class ProductSalesData extends Equatable {
  final String productId;
  final String productName;
  final int totalQuantitySold;
  final double totalRevenueGenerated;

  const ProductSalesData({
    required this.productId,
    required this.productName,
    required this.totalQuantitySold,
    required this.totalRevenueGenerated,
  });

  @override
  List<Object> get props => [productId, productName, totalQuantitySold, totalRevenueGenerated];
}

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final List<TransactionModel> transactions;
  final double totalRevenue;
  final double totalCostOfGoodsSold;
  final double grossProfit;
  final List<ChartData> chartData;
  final List<ProductSalesData> bestSellingProducts; // Data produk terlaris

  const ReportsLoaded({
    required this.transactions,
    required this.totalRevenue,
    required this.totalCostOfGoodsSold,
    required this.grossProfit,
    required this.chartData,
    required this.bestSellingProducts,
  });

  @override
  List<Object> get props => [transactions, totalRevenue, totalCostOfGoodsSold, grossProfit, chartData, bestSellingProducts];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object> get props => [message];
}
