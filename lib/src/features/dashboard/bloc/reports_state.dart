part of 'reports_bloc.dart';

class ChartData extends Equatable {
  final String label;
  final double value;
  final int numberOfTransactions;

  const ChartData({required this.label, required this.value, required this.numberOfTransactions});

  @override
  List<Object> get props => [label, value, numberOfTransactions];
}

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
  final List<ProductSalesData> bestSellingProducts;
  final ReportType reportType;

  const ReportsLoaded({
    required this.transactions,
    required this.totalRevenue,
    required this.totalCostOfGoodsSold,
    required this.grossProfit,
    required this.chartData,
    required this.bestSellingProducts,
    required this.reportType,
  });

  @override
  List<Object> get props => [
        transactions,
        totalRevenue,
        totalCostOfGoodsSold,
        grossProfit,
        chartData,
        bestSellingProducts,
        reportType,
      ];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object> get props => [message];
}
