part of 'dashboard_bloc.dart';

class DashboardChartData {
  final String label;
  final double value;

  DashboardChartData({required this.label, required this.value});
}

class DashboardTopProduct {
  final String name;
  final int quantity;

  DashboardTopProduct({required this.name, required this.quantity});
}


abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final double totalRevenueToday;
  final int transactionCountToday;
  final List<DashboardChartData> weeklySales;
  final List<DashboardTopProduct> topProducts;

  const DashboardLoaded({
    required this.totalRevenueToday,
    required this.transactionCountToday,
    required this.weeklySales,
    required this.topProducts,
  });

  @override
  List<Object> get props => [totalRevenueToday, transactionCountToday, weeklySales, topProducts];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
}
