
part of 'cart_bloc.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double total;

  const CartState({
    this.items = const [],
    this.subtotal = 0,
    this.tax = 0,
    this.total = 0,
  });

  CartState copyWith({
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? total,
  }) {
    return CartState(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
    );
  }

  @override
  List<Object> get props => [items, subtotal, tax, total];
}
