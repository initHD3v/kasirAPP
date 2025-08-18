
part of 'product_bloc.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

// State awal
class ProductInitial extends ProductState {}

// State saat sedang memuat data
class ProductLoading extends ProductState {}

// State saat data berhasil dimuat
class ProductLoaded extends ProductState {
  final List<Product> products;

  const ProductLoaded(this.products);

  @override
  List<Object> get props => [products];
}

// State saat terjadi error
class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}
