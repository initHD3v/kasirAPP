part of 'reports_bloc.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object> get props => [];
}

class LoadReports extends ReportsEvent {
  final DateTime startTime;
  final DateTime endTime;
  final ReportType reportType;

  const LoadReports({required this.startTime, required this.endTime, required this.reportType});

  @override
  List<Object> get props => [startTime, endTime, reportType];
}

class DeleteAllTransactions extends ReportsEvent {}
