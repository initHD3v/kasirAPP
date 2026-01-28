
import 'package:get_it/get_it.dart';
import 'package:kasir_app/src/core/services/printing_service.dart';
import 'package:kasir_app/src/data/repositories/auth_repository.dart';
import 'package:kasir_app/src/data/repositories/product_repository.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:kasir_app/src/data/repositories/user_repository.dart';
import 'services/database_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Services
  getIt.registerLazySingleton(() => DatabaseService());
  final printingService = PrintingService();
  getIt.registerSingleton<PrintingService>(printingService);
  await printingService.init();

  // Repositories
  getIt.registerLazySingleton(() => AuthRepository());
  getIt.registerLazySingleton(() => ProductRepository());
  getIt.registerLazySingleton(() => TransactionRepository());
  getIt.registerLazySingleton(() => UserRepository());
}
