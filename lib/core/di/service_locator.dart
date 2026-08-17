import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/admin_login_usecase.dart';
import '../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../features/auth/domain/usecases/verify_admin_otp_usecase.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';

/// Global service locator instance. Access anywhere via [sl<T>()].
final GetIt sl = GetIt.instance;

/// Registers all app dependencies. Call once in [main] before [runApp].
Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: AppConstants.apiBaseUrl),
  );

  sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage());

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: sl<ApiClient>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );

  sl.registerLazySingleton<AdminLoginUseCase>(
    () => AdminLoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<VerifyAdminOtpUseCase>(
    () => VerifyAdminOtpUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<RestoreSessionUseCase>(
    () => RestoreSessionUseCase(sl<AuthRepository>()),
  );
}
