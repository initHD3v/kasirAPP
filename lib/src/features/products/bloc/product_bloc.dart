import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:kasir_app/src/data/repositories/product_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _productRepository;

  ProductBloc(this._productRepository) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  void _onLoadProducts(LoadProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await _productRepository.getProducts(query: event.query);
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onAddProduct(AddProduct event, Emitter<ProductState> emit) async {
    try {
      await _productRepository.insertProduct(event.product);
      add(LoadProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onUpdateProduct(UpdateProduct event, Emitter<ProductState> emit) async {
    try {
      await _productRepository.updateProduct(event.product);
      add(LoadProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onDeleteProduct(DeleteProduct event, Emitter<ProductState> emit) async {
    try {
      await _productRepository.deleteProduct(event.id);
      add(LoadProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}