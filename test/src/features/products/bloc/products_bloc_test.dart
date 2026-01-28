import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:kasir_app/src/data/repositories/product_repository.dart';
import 'package:kasir_app/src/features/products/bloc/product_bloc.dart';
import 'package:kasir_app/src/features/products/bloc/product_event.dart';
import 'package:kasir_app/src/features/products/bloc/product_state.dart';

// Mock ProductRepository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late ProductRepository productRepository;
  late ProductBloc productBloc;

  // Dummy Product for testing
  const dummyProduct1 = Product(
    id: 'prod1',
    name: 'Product A',
    price: 10000.0,
    cost: 5000.0,
    category: 'Food',
    imageUrl: 'http://example.com/a.png',
  );

  const dummyProduct2 = Product(
    id: 'prod2',
    name: 'Product B',
    price: 20000.0,
    cost: 10000.0,
    category: 'Drink',
    imageUrl: null,
  );

  final List<Product> dummyProducts = [dummyProduct1, dummyProduct2];

  setUpAll(() {
    registerFallbackValue(dummyProduct1); // Register fallback for Product
  });

  setUp(() {
    productRepository = MockProductRepository();
    productBloc = ProductBloc(productRepository);
  });

  tearDown(() {
    productBloc.close();
  });

  group('ProductBloc', () {
    test('initial state is ProductInitial', () {
      expect(productBloc.state, equals(ProductInitial()));
    });

    blocTest<ProductBloc, ProductState>(
      'emits [ProductLoading, ProductLoaded] when LoadProducts is added and successful',
      build: () {
        when(() => productRepository.getProducts(query: any(named: 'query')))
            .thenAnswer((_) async => dummyProducts);
        return productBloc;
      },
      act: (bloc) => bloc.add(const LoadProducts()),
      expect: () => [
        ProductLoading(),
        ProductLoaded(dummyProducts),
      ],
      verify: (_) {
        verify(() => productRepository.getProducts(query: '')).called(1);
      },
    );

    blocTest<ProductBloc, ProductState>(
      'emits [ProductLoading, ProductError] when LoadProducts is added and fails',
      build: () {
        when(() => productRepository.getProducts(query: any(named: 'query')))
            .thenThrow(Exception('Failed to load products'));
        return productBloc;
      },
      act: (bloc) => bloc.add(const LoadProducts()),
      expect: () => [
        ProductLoading(),
        const ProductError('Exception: Failed to load products'),
      ],
      verify: (_) {
        verify(() => productRepository.getProducts(query: '')).called(1);
      },
    );

    blocTest<ProductBloc, ProductState>(
      'emits [ProductLoading, ProductLoaded] when AddProduct is added and successful',
      build: () {
        when(() => productRepository.insertProduct(any()))
            .thenAnswer((_) async => Future.value());
        when(() => productRepository.getProducts(query: any(named: 'query')))
            .thenAnswer((_) async => dummyProducts);
        return productBloc;
      },
      act: (bloc) => bloc.add(const AddProduct(dummyProduct1)),
      expect: () => [
        ProductLoading(), // Emitted by LoadProducts after AddProduct
        ProductLoaded(dummyProducts), // Emitted by LoadProducts after AddProduct
      ],
      verify: (_) {
        verify(() => productRepository.insertProduct(dummyProduct1)).called(1);
        verify(() => productRepository.getProducts(query: '')).called(1);
      },
    );

    blocTest<ProductBloc, ProductState>(
      'emits [ProductError] when AddProduct is added and fails',
      build: () {
        when(() => productRepository.insertProduct(any()))
            .thenThrow(Exception('Failed to add product'));
        return productBloc;
      },
      act: (bloc) => bloc.add(const AddProduct(dummyProduct1)),
      expect: () => [
        const ProductError('Exception: Failed to add product'),
      ],
      verify: (_) {
        verify(() => productRepository.insertProduct(dummyProduct1)).called(1);
        verifyNoMoreInteractions(productRepository); // No getProducts called
      },
    );

    blocTest<ProductBloc, ProductState>(
      'emits [ProductLoading, ProductLoaded] when UpdateProduct is added and successful',
      build: () {
        when(() => productRepository.updateProduct(any()))
            .thenAnswer((_) async => Future.value());
        when(() => productRepository.getProducts(query: any(named: 'query')))
            .thenAnswer((_) async => dummyProducts);
        return productBloc;
      },
      act: (bloc) => bloc.add(const UpdateProduct(dummyProduct1)),
      expect: () => [
        ProductLoading(), // Emitted by LoadProducts after UpdateProduct
        ProductLoaded(dummyProducts), // Emitted by LoadProducts after UpdateProduct
      ],
      verify: (_) {
        verify(() => productRepository.updateProduct(dummyProduct1)).called(1);
        verify(() => productRepository.getProducts(query: '')).called(1);
      },
    );

    blocTest<ProductBloc, ProductState>(
      'emits [ProductError] when UpdateProduct is added and fails',
      build: () {
        when(() => productRepository.updateProduct(any()))
            .thenThrow(Exception('Failed to update product'));
        return productBloc;
      },
      act: (bloc) => bloc.add(const UpdateProduct(dummyProduct1)),
      expect: () => [
        const ProductError('Exception: Failed to update product'),
      ],
      verify: (_) {
        verify(() => productRepository.updateProduct(dummyProduct1)).called(1);
        verifyNoMoreInteractions(productRepository);
      },
    );

    blocTest<ProductBloc, ProductState>(
      'emits [ProductLoading, ProductLoaded] when DeleteProduct is added and successful',
      build: () {
        when(() => productRepository.deleteProduct(any()))
            .thenAnswer((_) async => Future.value());
        when(() => productRepository.getProducts(query: any(named: 'query')))
            .thenAnswer((_) async => dummyProducts);
        return productBloc;
      },
      act: (bloc) => bloc.add(const DeleteProduct('prod1')),
      expect: () => [
        ProductLoading(), // Emitted by LoadProducts after DeleteProduct
        ProductLoaded(dummyProducts), // Emitted by LoadProducts after DeleteProduct
      ],
      verify: (_) {
        verify(() => productRepository.deleteProduct('prod1')).called(1);
        verify(() => productRepository.getProducts(query: '')).called(1);
      },
    );

    blocTest<ProductBloc, ProductState>(
      'emits [ProductError] when DeleteProduct is added and fails',
      build: () {
        when(() => productRepository.deleteProduct(any()))
            .thenThrow(Exception('Failed to delete product'));
        return productBloc;
      },
      act: (bloc) => bloc.add(const DeleteProduct('prod1')),
      expect: () => [
        const ProductError('Exception: Failed to delete product'),
      ],
      verify: (_) {
        verify(() => productRepository.deleteProduct('prod1')).called(1);
        verifyNoMoreInteractions(productRepository);
      },
    );
  });
}