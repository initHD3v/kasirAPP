
part of 'reports_bloc.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object> get props => [];
}

class LoadReports extends ReportsEvent {
  final DateTime startTime;
  final DateTime endTime;

  const LoadReports({required this.startTime, required this.endTime});

  @override
  List<Object> get props => [startTime, endTime];
}

class DeleteAllTransactions extends ReportsEvent {
  const DeleteAllTransactions();

  @override
  List<Object> get props => [];
}
