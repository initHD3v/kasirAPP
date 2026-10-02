
part of 'transaction_bloc.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object> get props => [];
}

class ProcessTransaction extends TransactionEvent {
  final List<CartItem> cartItems;
  final double totalAmount;
  final double amountPaid;
  final double change;
  final String cashierId;
  final String paymentMethod;

  const ProcessTransaction({
    required this.cartItems,
    required this.totalAmount,
    required this.amountPaid,
    required this.change,
    required this.cashierId,
    this.paymentMethod = 'Tunai',
  });

  @override
  List<Object> get props =>
      [cartItems, totalAmount, amountPaid, change, cashierId, paymentMethod];
}
