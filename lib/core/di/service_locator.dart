import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/admin_login_usecase.dart';
import '../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../features/auth/domain/usecases/verify_admin_otp_usecase.dart';
import '../../features/partnerships/data/repositories/partnership_repository_impl.dart';
import '../../features/partnerships/domain/repositories/partnership_repository.dart';
import '../../features/partnerships/domain/usecases/partnership_usecases.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../network/authenticated_api.dart';

/// Global service locator instance. Access anywhere via [sl<T>()].
final GetIt sl = GetIt.instance;

/// Registers all app dependencies. Call once in [main] before [runApp].
Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: AppConstants.apiBaseUrl),
  );

  sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage());

  /// Attaches the admin's bearer token to every authenticated call. The auth
  /// repository deliberately does not use it — its login routes reject
  /// requests that carry a token.
  sl.registerLazySingleton<AuthenticatedApi>(
    () => AuthenticatedApi(
      apiClient: sl<ApiClient>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );

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

  // ─── Pharmacy partnerships ──────────────────────────────────────────────────
  sl.registerLazySingleton<PartnershipRepository>(
    () => PartnershipRepositoryImpl(api: sl<AuthenticatedApi>()),
  );

  sl.registerLazySingleton<LoadPharmacyDirectoryUseCase>(
    () => LoadPharmacyDirectoryUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<LoadPartnershipOverviewUseCase>(
    () => LoadPartnershipOverviewUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<GetGroupDetailUseCase>(
    () => GetGroupDetailUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<CreateGroupUseCase>(
    () => CreateGroupUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<UpdateGroupUseCase>(
    () => UpdateGroupUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<AssignPharmacyToGroupUseCase>(
    () => AssignPharmacyToGroupUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<RemovePharmacyFromGroupUseCase>(
    () => RemovePharmacyFromGroupUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<MovePharmacyToGroupUseCase>(
    () => MovePharmacyToGroupUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<CreateAgreementUseCase>(
    () => CreateAgreementUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<SetAgreementStatusUseCase>(
    () => SetAgreementStatusUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<GetAgreementDetailUseCase>(
    () => GetAgreementDetailUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<GetPharmacyComplianceUseCase>(
    () => GetPharmacyComplianceUseCase(sl<PartnershipRepository>()),
  );
  sl.registerLazySingleton<GetComplianceReportUseCase>(
    () => GetComplianceReportUseCase(sl<PartnershipRepository>()),
  );
}
