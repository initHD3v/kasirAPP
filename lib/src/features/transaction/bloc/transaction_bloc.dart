
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kasir_app/src/data/models/cart_item_model.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _transactionRepository;

  TransactionBloc(this._transactionRepository) : super(TransactionInitial()) {
    on<ProcessTransaction>(_onProcessTransaction);
  }

  void _onProcessTransaction(
    ProcessTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    print('ProcessTransaction event received');
    emit(TransactionInProgress());
    print('Emitted TransactionInProgress');
    try {
      final newTransaction = TransactionModel(
        id: const Uuid().v4(),
        items: event.cartItems,
        totalAmount: event.totalAmount,
        paymentMethod: 'Tunai', // Default to Tunai for cash transactions
        amountPaid: event.amountPaid,
        change: event.change,
        cashierId: event.cashierId,
        createdAt: DateTime.now(),
      );

      print('Adding transaction to repository');
      await _transactionRepository.addTransaction(newTransaction);
      print('Transaction added to repository');
      emit(TransactionSuccess(newTransaction));
      print('Emitted TransactionSuccess');
    } catch (e) {
      print('Error in _onProcessTransaction: ${e.toString()}');
      emit(TransactionFailure(e.toString()));
      print('Emitted TransactionFailure');
    }
  }
}
