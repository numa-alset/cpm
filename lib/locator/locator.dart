import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/dao/fatora_dao.dart';
import 'package:naji/core/dao/fatora_product_dao.dart';
import 'package:naji/core/dao/payment_dao.dart';
import 'package:naji/core/dao/product_dao.dart';
// DAOs
import 'package:naji/core/dao/user_dao.dart';
import 'package:naji/core/database/database_helper.dart';
import 'package:naji/core/database/fatora_db.dart';
import 'package:naji/core/database/payment_db.dart';
import 'package:naji/core/database/product_db.dart';
import 'package:naji/core/database/products_fatoras_db.dart';
import 'package:naji/core/database/user_db.dart';
import 'package:naji/core/repositories/fatora_product_repository.dart';
import 'package:naji/core/repositories/fatora_repository.dart';
import 'package:naji/core/repositories/payment_repository.dart';
import 'package:naji/core/repositories/product_repository.dart';
// Repositories
import 'package:naji/core/repositories/user_repository.dart';
import 'package:naji/core/router/go_router.dart' as app_router;
import 'package:naji/core/services/backup_service.dart';
import 'package:naji/core/services/device_service.dart';
import 'package:naji/core/services/import_service.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/core/services/product_service.dart';
import 'package:naji/core/services/statistics_service.dart';
import 'package:naji/core/services/sync_service.dart';
import 'package:naji/core/services/transaction_service.dart';
import 'package:naji/core/services/user_service.dart';
import 'package:naji/core/services/validation_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final db = DatabaseHelper.instance;
  await db.database;

  getIt.registerSingleton(db);

  // Register GoRouter
  getIt.registerSingleton<GoRouter>(app_router.router);

  // Database helpers
  getIt.registerLazySingleton(() => UserDB());
  getIt.registerLazySingleton(() => ProductDB());
  getIt.registerLazySingleton(() => FatoraDB());
  getIt.registerLazySingleton(() => PaymentDB());
  getIt.registerLazySingleton(() => FatoraProductsDB());

  // DAOs
  getIt.registerLazySingleton(() => UserDAO());
  getIt.registerLazySingleton(() => ProductDAO());
  getIt.registerLazySingleton(() => FatoraDAO());
  getIt.registerLazySingleton(() => FatoraProductDAO());
  getIt.registerLazySingleton(() => PaymentDAO());

  // Repositories
  getIt.registerLazySingleton(() => UserRepository(getIt<UserDAO>()));
  getIt.registerLazySingleton(() => ProductRepository(getIt<ProductDAO>()));
  getIt.registerLazySingleton(
    () => FatoraProductRepository(getIt<FatoraProductDAO>()),
  );
  getIt.registerLazySingleton(
    () => FatoraRepository(getIt<FatoraDAO>(), getIt<FatoraProductDAO>()),
  );
  getIt.registerLazySingleton(() => PaymentRepository(getIt<PaymentDAO>()));

  // Core services
  getIt.registerLazySingleton(() => ValidationService());
  getIt.registerLazySingleton(() => TransactionService());
  getIt.registerLazySingleton(
    () => InvoiceService(
      getIt<FatoraRepository>(),
      getIt<FatoraProductRepository>(),
      getIt<UserRepository>(),
      getIt<TransactionService>(),
    ),
  );
  getIt.registerLazySingleton(
    () => UserService(getIt<UserRepository>(), getIt<TransactionService>()),
  );
  // IdService is static - no need to register an instance
  getIt.registerLazySingleton(
    () => StatisticsService(
      getIt<FatoraRepository>(),
      getIt<PaymentRepository>(),
      getIt<UserRepository>(),
      getIt<FatoraProductRepository>(),
    ),
  );
  getIt.registerLazySingleton(() => DeviceService());
  getIt.registerLazySingleton(
    () => PaymentService(
      getIt<PaymentRepository>(),
      getIt<UserRepository>(),
      getIt<TransactionService>(),
    ),
  );
  getIt.registerLazySingleton(
    () =>
        ProductService(getIt<ProductRepository>(), getIt<TransactionService>()),
  );

  // Utilities
  getIt.registerLazySingleton(() => BackupService());
  getIt.registerLazySingleton(() => ImportService());
  getIt.registerLazySingleton(() => SyncService());
}
