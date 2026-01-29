import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kasir_app/src/core/app_router.dart';
import 'package:kasir_app/src/core/services/database_service.dart';
import 'package:kasir_app/src/core/services/printing_service.dart';
import 'src/core/service_locator.dart';
import 'package:kasir_app/src/data/repositories/product_repository.dart';
import 'package:kasir_app/src/features/products/bloc/product_bloc.dart';
import 'package:kasir_app/src/features/products/bloc/product_event.dart';
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';
import 'package:kasir_app/src/data/repositories/auth_repository.dart'; // Add this import
import 'package:intl/date_symbol_data_local.dart'; // New import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); // Initialize date formatting for Indonesian locale
  await setupLocator();
  await getIt<DatabaseService>().database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Sediakan AuthBloc di level tertinggi aplikasi
    return BlocProvider(
      create: (context) => AuthBloc(getIt<AuthRepository>())..add(AppStarted()),
      child: Builder(builder: (context) {
        return BlocProvider(
          create: (context) => ProductBloc(
            getIt<ProductRepository>(),
          )..add(LoadProducts()),
          child: MaterialApp.router(
            title: 'Aplikasi Kasir',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            ),
            // Gunakan router yang sudah mendengarkan AuthBloc
            routerConfig: AppRouter(context.read<AuthBloc>()).router,
          ),
        );
      }),
    );
  }
}