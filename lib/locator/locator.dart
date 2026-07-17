final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final db = DatabaseHelper();
  await db.database;

  getIt.registerSingleton(db);

  // Database helpers
  getIt.registerLazySingleton(() => UserDB());
  getIt.registerLazySingleton(() => ProductDB());
  getIt.registerLazySingleton(() => FatoraDB());
  getIt.registerLazySingleton(() => PaymentDB());
  getIt.registerLazySingleton(() => FatoraProductsDB());

  // Core services
  getIt.registerLazySingleton(() => ValidationService());
  getIt.registerLazySingleton(() => InvoiceService());
  getIt.registerLazySingleton(() => TransactionService());
  getIt.registerLazySingleton(() => UserService());
  getIt.registerLazySingleton(() => IdService());
  getIt.registerLazySingleton(() => StatisticsService());
  getIt.registerLazySingleton(() => DeviceService());
  getIt.registerLazySingleton(() => PaymentService());
  getIt.registerLazySingleton(() => ProductService());

  // Utilities
  getIt.registerLazySingleton(() => BackupService());
  getIt.registerLazySingleton(() => ImportService());
  getIt.registerLazySingleton(() => SyncService());
}
