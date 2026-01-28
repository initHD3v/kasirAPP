import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kasir_app/src/data/models/cart_item_model.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:kasir_app/src/features/reports/bloc/reports_bloc.dart';
import 'package:intl/intl.dart'; // Needed for date formatting in ReportsBloc

// Mock TransactionRepository
class MockTransactionRepository extends Mock implements TransactionRepository {}

// Fakes for non-primitive types used with any()
class FakeTransactionModel extends Fake implements TransactionModel {}
class FakeDateTime extends Fake implements DateTime {}
class FakeChartData extends Fake implements ChartData {}
class FakeProductSalesData extends Fake implements ProductSalesData {}


void main() {
  late MockTransactionRepository mockTransactionRepository;
  late ReportsBloc reportsBloc;

  // Dummy Data
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  final twoDaysAgo = now.subtract(const Duration(days: 2));

  final dummyProduct1 = Product(id: 'p1', name: 'Product A', price: 100.0, cost: 50.0);
  final dummyProduct2 = Product(id: 'p2', name: 'Product B', price: 200.0, cost: 100.0);

  final dummyCartItem1 = CartItem(product: dummyProduct1, quantity: 1, costAtSale: 50.0);
  final dummyCartItem2 = CartItem(product: dummyProduct2, quantity: 1, costAtSale: 100.0);
  final dummyCartItem1x2 = CartItem(product: dummyProduct1, quantity: 2, costAtSale: 50.0);

  final dummyTransaction1 = TransactionModel(
    id: 't1',
    items: [dummyCartItem1, dummyCartItem2], // Total Revenue: 100 + 200 = 300, Total Cost: 50 + 100 = 150
    totalAmount: 300.0,
    paymentMethod: 'Cash',
    amountPaid: 300.0,
    change: 0.0,
    cashierId: 'c1',
    createdAt: twoDaysAgo,
  );

  final dummyTransaction2 = TransactionModel(
    id: 't2',
    items: [dummyCartItem1x2], // Total Revenue: 100*2 = 200, Total Cost: 50*2 = 100
    totalAmount: 200.0,
    paymentMethod: 'Cash',
    amountPaid: 200.0,
    change: 0.0,
    cashierId: 'c1',
    createdAt: yesterday,
  );

  final List<TransactionModel> dummyTransactions = [dummyTransaction1, dummyTransaction2];

  setUpAll(() {
    registerFallbackValue(FakeTransactionModel());
    registerFallbackValue(FakeDateTime());
    registerFallbackValue(FakeChartData());
    registerFallbackValue(FakeProductSalesData());
  });

  setUp(() {
    mockTransactionRepository = MockTransactionRepository();
    reportsBloc = ReportsBloc(mockTransactionRepository);
  });

  tearDown(() {
    reportsBloc.close();
  });

  group('ReportsBloc', () {
    test('initial state is ReportsInitial', () {
      expect(reportsBloc.state, equals(ReportsInitial()));
    });

    blocTest<ReportsBloc, ReportsState>(
      'emits [ReportsLoading, ReportsLoaded] when LoadReports is added and successful',
      build: () {
        when(() => mockTransactionRepository.getTransactionsInRange(any(), any()))
            .thenAnswer((_) async => dummyTransactions);
        return reportsBloc;
      },
      act: (bloc) => bloc.add(LoadReports(startTime: twoDaysAgo, endTime: now)),
      expect: () {
        // Expected calculations
        const expectedTotalRevenue = 500.0; // 300 + 200
        const expectedTotalCostOfGoodsSold = 250.0; // 150 + 100
        const expectedGrossProfit = 250.0; // 500 - 250

        // Format dates as expected by the BLoC logic for chart labels
        final DateFormat formatter = DateFormat('E');
        final expectedChartData = [
          ChartData(label: formatter.format(yesterday), value: dummyTransaction2.totalAmount),
          ChartData(label: formatter.format(twoDaysAgo), value: dummyTransaction1.totalAmount),
        ];

        final expectedBestSellingProducts = [
          const ProductSalesData(
              productId: 'p1',
              productName: 'Product A',
              totalQuantitySold: 3, // 1 from t1, 2 from t2
              totalRevenueGenerated: 300.0 // 100 from t1, 200 from t2
          ),
          const ProductSalesData(
              productId: 'p2',
              productName: 'Product B',
              totalQuantitySold: 1, // 1 from t1
              totalRevenueGenerated: 200.0 // 200 from t1
          ),
        ];

        return [
          ReportsLoading(),
          ReportsLoaded(
            transactions: dummyTransactions,
            totalRevenue: expectedTotalRevenue,
            totalCostOfGoodsSold: expectedTotalCostOfGoodsSold,
            grossProfit: expectedGrossProfit,
            chartData: expectedChartData,
            bestSellingProducts: expectedBestSellingProducts,
          ),
        ];
      },
      verify: (_) {
        verify(() => mockTransactionRepository.getTransactionsInRange(twoDaysAgo, now)).called(1);
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'emits [ReportsLoading, ReportsError] when LoadReports is added and fails',
      build: () {
        when(() => mockTransactionRepository.getTransactionsInRange(any(), any()))
            .thenThrow(Exception('Failed to load reports'));
        return reportsBloc;
      },
      act: (bloc) => bloc.add(LoadReports(startTime: twoDaysAgo, endTime: now)),
      expect: () => [
        ReportsLoading(),
        const ReportsError('Exception: Failed to load reports'),
      ],
      verify: (_) {
        verify(() => mockTransactionRepository.getTransactionsInRange(twoDaysAgo, now)).called(1);
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'calls deleteAllTransactions and then LoadReports event on successful DeleteAllTransactions',
      build: () {
        when(() => mockTransactionRepository.deleteAllTransactions())
            .thenAnswer((_) async => Future.value());
        when(() => mockTransactionRepository.getTransactionsInRange(any(), any()))
            .thenAnswer((_) async => []); // Empty list after deletion
        return reportsBloc;
      },
      act: (bloc) => bloc.add(const DeleteAllTransactions()),
      expect: () => [
        ReportsLoading(),
        isA<ReportsLoaded>()
            .having((s) => s.transactions, 'transactions', isEmpty)
            .having((s) => s.totalRevenue, 'totalRevenue', 0.0), // Ensure calculations reflect empty state
      ],
      verify: (_) {
        verify(() => mockTransactionRepository.deleteAllTransactions()).called(1);
        // Verify LoadReports is called with specific range
        verify(() => mockTransactionRepository.getTransactionsInRange(
          any(that: isA<DateTime>()),
          any(that: isA<DateTime>()),
        )).called(1);
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'emits [ReportsLoading, ReportsError] when DeleteAllTransactions is added and fails',
      build: () {
        when(() => mockTransactionRepository.deleteAllTransactions())
            .thenThrow(Exception('Failed to delete all transactions'));
        return reportsBloc;
      },
      act: (bloc) => bloc.add(const DeleteAllTransactions()),
      expect: () => [
        ReportsLoading(),
        const ReportsError('Exception: Failed to delete all transactions'),
      ],
      verify: (_) {
        verify(() => mockTransactionRepository.deleteAllTransactions()).called(1);
        verifyNoMoreInteractions(mockTransactionRepository); // getTransactionsInRange should not be called
      },
    );
  });
}