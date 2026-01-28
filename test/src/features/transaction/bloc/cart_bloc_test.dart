import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kasir_app/src/data/models/cart_item_model.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:kasir_app/src/features/transaction/bloc/cart_bloc.dart';

// Dummy Product for testing
const dummyProduct1 = Product(
  id: 'p1',
  name: 'Product A',
  price: 10.0,
  cost: 5.0,
);
const dummyProduct2 = Product(
  id: 'p2',
  name: 'Product B',
  price: 20.0,
  cost: 10.0,
);

// Dummy CartItem for testing
final dummyCartItem1 = CartItem(product: dummyProduct1, quantity: 1, costAtSale: dummyProduct1.cost);
final dummyCartItem2 = CartItem(product: dummyProduct2, quantity: 1, costAtSale: dummyProduct2.cost);

// Fake classes for mocktail, though not strictly needed since CartItem and Product are equatable and const/immutable
class FakeProduct extends Fake implements Product {}
class FakeCartItem extends Fake implements CartItem {}

void main() {
  late CartBloc cartBloc;

  setUpAll(() {
    registerFallbackValue(FakeProduct());
    registerFallbackValue(FakeCartItem());
  });

  setUp(() {
    cartBloc = CartBloc();
  });

  tearDown(() {
    cartBloc.close();
  });

  group('CartBloc', () {
    test('initial state is CartState with empty items and zero totals', () {
      expect(cartBloc.state, const CartState(items: [], subtotal: 0, total: 0));
    });

    blocTest<CartBloc, CartState>(
      'emits state with one item when AddItem is added for a new product',
      build: () => cartBloc,
      act: (bloc) => bloc.add(const AddItem(dummyProduct1)),
      expect: () => [
        CartState(items: [dummyCartItem1], subtotal: 10.0, total: 10.0),
      ],
    );

    blocTest<CartBloc, CartState>(
      'emits state with incremented quantity when AddItem is added for an existing product',
      build: () => cartBloc,
      seed: () => CartState(items: [dummyCartItem1], subtotal: 10.0, total: 10.0),
      act: (bloc) => bloc.add(const AddItem(dummyProduct1)),
      expect: () => [
        CartState(items: [dummyCartItem1.copyWith(quantity: 2)], subtotal: 20.0, total: 20.0),
      ],
    );

    blocTest<CartBloc, CartState>(
      'emits state with item removed when RemoveItem is added',
      build: () => cartBloc,
      seed: () => CartState(items: [dummyCartItem1, dummyCartItem2], subtotal: 30.0, total: 30.0),
      act: (bloc) => bloc.add(RemoveItem(dummyCartItem1)),
      expect: () => [
        CartState(items: [dummyCartItem2], subtotal: 20.0, total: 20.0),
      ],
    );

    blocTest<CartBloc, CartState>(
      'emits state with incremented quantity when IncrementItemQuantity is added',
      build: () => cartBloc,
      seed: () => CartState(items: [dummyCartItem1.copyWith(quantity: 1)], subtotal: 10.0, total: 10.0),
      act: (bloc) => bloc.add(IncrementItemQuantity(dummyCartItem1)),
      expect: () => [
        CartState(items: [dummyCartItem1.copyWith(quantity: 2)], subtotal: 20.0, total: 20.0),
      ],
    );

    blocTest<CartBloc, CartState>(
      'emits state with decremented quantity when DecrementItemQuantity is added and quantity > 1',
      build: () => cartBloc,
      seed: () => CartState(items: [dummyCartItem1.copyWith(quantity: 2)], subtotal: 20.0, total: 20.0),
      act: (bloc) => bloc.add(DecrementItemQuantity(dummyCartItem1.copyWith(quantity: 2))),
      expect: () => [
        CartState(items: [dummyCartItem1.copyWith(quantity: 1)], subtotal: 10.0, total: 10.0),
      ],
    );

    blocTest<CartBloc, CartState>(
      'emits state with item removed when DecrementItemQuantity is added and quantity = 1',
      build: () => cartBloc,
      seed: () => CartState(items: [dummyCartItem1], subtotal: 10.0, total: 10.0),
      act: (bloc) => bloc.add(DecrementItemQuantity(dummyCartItem1)),
      expect: () => [
        const CartState(items: [], subtotal: 0.0, total: 0.0),
      ],
    );

    blocTest<CartBloc, CartState>(
      'emits state with empty items when ClearCart is added',
      build: () => cartBloc,
      seed: () => CartState(items: [dummyCartItem1, dummyCartItem2], subtotal: 30.0, total: 30.0),
      act: (bloc) => bloc.add(ClearCart()),
      expect: () => [
        const CartState(items: [], subtotal: 0.0, total: 0.0),
      ],
    );

    blocTest<CartBloc, CartState>(
      'emits state with reordered items when ReorderCartItems is added (moving item up)',
      build: () => cartBloc,
      seed: () => CartState(items: [dummyCartItem1, dummyCartItem2], subtotal: 30.0, total: 30.0),
      act: (bloc) => bloc.add(const ReorderCartItems(1, 0)), // Move dummyCartItem2 (index 1) to index 0
      expect: () => [
        CartState(items: [dummyCartItem2, dummyCartItem1], subtotal: 30.0, total: 30.0),
      ],
    );

    blocTest<CartBloc, CartState>(
      'emits state with reordered items when ReorderCartItems is added (moving item down)',
      build: () => cartBloc,
      seed: () => CartState(items: [dummyCartItem2, dummyCartItem1], subtotal: 30.0, total: 30.0),
      act: (bloc) => bloc.add(const ReorderCartItems(0, 1)), // Move dummyCartItem2 (index 0) to index 1
      expect: () => [
        CartState(items: [dummyCartItem1, dummyCartItem2], subtotal: 30.0, total: 30.0),
      ],
    );
  });
}