import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final TransactionRepository _transactionRepository;

  DashboardBloc(this._transactionRepository) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  void _onLoadDashboardData(LoadDashboardData event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final data = await _transactionRepository.getDashboardData();
      
      emit(DashboardLoaded(
        totalRevenueToday: data['totalRevenueToday'],
        transactionCountToday: data['transactionCountToday'],
        weeklySales: data['weeklySales'],
        topProducts: data['topProducts'],
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
