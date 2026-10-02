
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kasir_app/src/data/models/cart_item_model.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

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
    if (event.cartItems.isEmpty) {
      emit(const TransactionFailure('Keranjang kosong.'));
      return;
    }
    if (event.totalAmount <= 0) {
      emit(const TransactionFailure('Total tidak valid.'));
      return;
    }
    if (event.amountPaid < event.totalAmount) {
      emit(const TransactionFailure('Jumlah bayar kurang dari total.'));
      return;
    }
    emit(TransactionInProgress());
    try {
      final newTransaction = TransactionModel(
        id: const Uuid().v4(),
        items: event.cartItems,
        totalAmount: event.totalAmount,
        paymentMethod: event.paymentMethod,
        amountPaid: event.amountPaid,
        change: event.change,
        cashierId: event.cashierId,
        createdAt: DateTime.now(),
      );

      debugPrint('TransactionBloc: Saving transaction to repository');
      await _transactionRepository.addTransaction(newTransaction);
      debugPrint('TransactionBloc: Transaction saved');
      emit(TransactionSuccess(newTransaction));
      debugPrint('TransactionBloc: Emitted TransactionSuccess');
    } catch (e) {
      debugPrint('TransactionBloc: Error during transaction processing: $e');
      emit(TransactionFailure(e.toString()));
      debugPrint('TransactionBloc: Emitted TransactionFailure');
    }
  }
}
