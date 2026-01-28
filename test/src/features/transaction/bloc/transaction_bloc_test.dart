import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kasir_app/src/data/models/cart_item_model.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:kasir_app/src/features/transaction/bloc/transaction_bloc.dart';

// Mock TransactionRepository
class MockTransactionRepository extends Mock implements TransactionRepository {}

// Fakes for non-primitive types used with any()
class FakeCartItem extends Fake implements CartItem {}
class FakeTransactionModel extends Fake implements TransactionModel {}
class FakeDateTime extends Fake implements DateTime {}


void main() {
  late MockTransactionRepository mockTransactionRepository;
  late TransactionBloc transactionBloc;

  // Dummy Product for CartItem
  const dummyProduct = Product(
    id: 'p1',
    name: 'Test Product',
    price: 100.0,
    cost: 50.0,
  );

  // Dummy CartItem for testing
  final dummyCartItem = CartItem(
    product: dummyProduct,
    quantity: 2,
    costAtSale: dummyProduct.cost,
  );
  final List<CartItem> dummyCartItems = [dummyCartItem];

  setUpAll(() {
    registerFallbackValue(FakeCartItem());
    registerFallbackValue(FakeTransactionModel());
    registerFallbackValue(FakeDateTime());
  });

  setUp(() {
    mockTransactionRepository = MockTransactionRepository();
    transactionBloc = TransactionBloc(mockTransactionRepository);
  });

  tearDown(() {
    transactionBloc.close();
  });

  group('TransactionBloc', () {
    test('initial state is TransactionInitial', () {
      expect(transactionBloc.state, equals(TransactionInitial()));
    });

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionInProgress, TransactionSuccess] when ProcessTransaction is added and successful',
      build: () {
        when(() => mockTransactionRepository.addTransaction(any()))
            .thenAnswer((_) async => Future.value());
        return transactionBloc;
      },
      act: (bloc) => bloc.add(
        ProcessTransaction(
          cartItems: dummyCartItems,
          totalAmount: 200.0,
          amountPaid: 200.0,
          change: 0.0,
          cashierId: 'cashier1',
        ),
      ),
      expect: () => [
        TransactionInProgress(),
        isA<TransactionSuccess>()
            .having((s) => s.transaction.items, 'items', dummyCartItems)
            .having((s) => s.transaction.totalAmount, 'totalAmount', 200.0)
            .having((s) => s.transaction.paymentMethod, 'paymentMethod', 'Tunai')
            .having((s) => s.transaction.amountPaid, 'amountPaid', 200.0)
            .having((s) => s.transaction.change, 'change', 0.0)
            .having((s) => s.transaction.cashierId, 'cashierId', 'cashier1'),
      ],
      verify: (_) {
        verify(() => mockTransactionRepository.addTransaction(any(that: isA<TransactionModel>()))).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionInProgress, TransactionFailure] when ProcessTransaction is added and fails',
      build: () {
        when(() => mockTransactionRepository.addTransaction(any()))
            .thenThrow(Exception('Failed to add transaction'));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(
        ProcessTransaction(
          cartItems: dummyCartItems,
          totalAmount: 200.0,
          amountPaid: 200.0,
          change: 0.0,
          cashierId: 'cashier1',
        ),
      ),
      expect: () => [
        TransactionInProgress(),
        isA<TransactionFailure>()
            .having((s) => s.error, 'error', 'Exception: Failed to add transaction'),
      ],
      verify: (_) {
        verify(() => mockTransactionRepository.addTransaction(any(that: isA<TransactionModel>()))).called(1);
      },
    );
  });
}