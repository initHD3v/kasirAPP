
part of 'transaction_bloc.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionInProgress extends TransactionState {}

class TransactionSuccess extends TransactionState {
  final TransactionModel transaction;

  const TransactionSuccess(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class TransactionFailure extends TransactionState {
  final String error;

  const TransactionFailure(this.error);

  @override
  List<Object> get props => [error];
}
