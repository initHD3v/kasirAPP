import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kasir_app/src/data/repositories/product_repository.dart';
import 'package:kasir_app/src/features/products/bloc/product_event.dart';
import 'package:kasir_app/src/features/products/bloc/product_state.dart';

import 'package:flutter/foundation.dart'; // Import for debugPrint

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _productRepository;

  ProductBloc(this._productRepository) : super(ProductInitial()) {
    debugPrint('ProductBloc initialized');
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  void _onLoadProducts(LoadProducts event, Emitter<ProductState> emit) async {
    debugPrint('Handling LoadProducts event with query: ${event.query}');
    emit(ProductLoading());
    try {
      final products = await _productRepository.getProducts(query: event.query);
      debugPrint('Products loaded: ${products.length}');
      emit(ProductLoaded(products));
    } catch (e) {
      debugPrint('Error loading products: $e');
      emit(ProductError(e.toString()));
    }
  }

  void _onAddProduct(AddProduct event, Emitter<ProductState> emit) async {
    debugPrint('Handling AddProduct event: ${event.product.name}');
    try {
      await _productRepository.insertProduct(event.product);
      debugPrint('Product added. Reloading products...');
      add(LoadProducts()); // Reload products after adding
    } catch (e) {
      debugPrint('Error adding product: $e');
      emit(ProductError(e.toString()));
    }
  }

  void _onUpdateProduct(UpdateProduct event, Emitter<ProductState> emit) async {
    debugPrint('Handling UpdateProduct event: ${event.product.name}');
    try {
      await _productRepository.updateProduct(event.product);
      debugPrint('Product updated. Reloading products...');
      add(LoadProducts()); // Reload products after updating
    } catch (e) {
      debugPrint('Error updating product: $e');
      emit(ProductError(e.toString()));
    }
  }

  void _onDeleteProduct(DeleteProduct event, Emitter<ProductState> emit) async {
    debugPrint('Handling DeleteProduct event for ID: ${event.id}');
    try {
      await _productRepository.deleteProduct(event.id);
      debugPrint('Product deleted. Reloading products...');
      add(LoadProducts()); // Reload products after deleting
    } catch (e) {
      debugPrint('Error deleting product: $e');
      emit(ProductError(e.toString()));
    }
  }
}
