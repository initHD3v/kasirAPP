
part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

// Event untuk menambah produk ke keranjang
class AddItem extends CartEvent {
  final Product product;

  const AddItem(this.product);

  @override
  List<Object> get props => [product];
}

// Event untuk menghapus item dari keranjang
class RemoveItem extends CartEvent {
  final CartItem item;

  const RemoveItem(this.item);

  @override
  List<Object> get props => [item];
}

// Event untuk menambah jumlah item
class IncrementItemQuantity extends CartEvent {
  final CartItem item;

  const IncrementItemQuantity(this.item);

  @override
  List<Object> get props => [item];
}

// Event untuk mengurangi jumlah item
class DecrementItemQuantity extends CartEvent {
  final CartItem item;

  const DecrementItemQuantity(this.item);

  @override
  List<Object> get props => [item];
}

// Event untuk membersihkan keranjang
class ClearCart extends CartEvent {}
