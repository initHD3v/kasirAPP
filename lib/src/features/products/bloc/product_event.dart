
import 'package:equatable/equatable.dart';
import 'package:kasir_app/src/data/models/product_model.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object> get props => [];
}

// Event untuk memuat semua produk, dengan opsi filter pencarian
class LoadProducts extends ProductEvent {
  final String query;
  final String? category; // New optional category filter

  const LoadProducts({this.query = '', this.category});

  @override
  List<Object> get props => [query, category ?? '']; // Include category in props
}

// Event untuk menambah produk
class AddProduct extends ProductEvent {
  final Product product;

  const AddProduct(this.product);

  @override
  List<Object> get props => [product];
}

// Event untuk memperbarui produk
class UpdateProduct extends ProductEvent {
  final Product product;

  const UpdateProduct(this.product);

  @override
  List<Object> get props => [product];
}

// Event untuk menghapus produk
class DeleteProduct extends ProductEvent {
  final String id;

  const DeleteProduct(this.id);

  @override
  List<Object> get props => [id];
}
