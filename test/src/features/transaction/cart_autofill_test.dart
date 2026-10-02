import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:kasir_app/src/features/transaction/bloc/cart_bloc.dart';
import 'package:kasir_app/src/features/transaction/bloc/transaction_bloc.dart';
import 'package:kasir_app/src/features/transaction/transaction_page.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

const _product = Product(id: 'p1', name: 'Nasi Goreng', price: 15000, cost: 9000);

/// Regresi: tombol PROSES PEMBAYARAN harus aktif otomatis setelah
/// Jumlah Bayar terisi total (tanpa user mengetik apa pun).
void main() {
  testWidgets('PROSES PEMBAYARAN aktif otomatis setelah autofill total',
      (tester) async {
    final cartBloc = CartBloc();
    addTearDown(cartBloc.close);
    cartBloc.add(const AddItem(_product));

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cartBloc),
            BlocProvider(
                create: (_) => TransactionBloc(MockTransactionRepository())),
          ],
          child: const Scaffold(body: CartPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextFormField);
    expect(field, findsOneWidget);
    expect(tester.widget<TextFormField>(field).controller?.text, '15.000');

    final btn = find.widgetWithText(ElevatedButton, 'PROSES PEMBAYARAN');
    expect(btn, findsOneWidget);
    expect(tester.widget<ElevatedButton>(btn).onPressed, isNotNull);
  });
}
