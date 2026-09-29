import 'package:redux/redux.dart';

import '../core/di/service_locator.dart';
import '../core/usecases/usecase.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/admin_login_usecase.dart';
import '../features/auth/domain/usecases/restore_session_usecase.dart';
import '../features/auth/domain/usecases/verify_admin_otp_usecase.dart';
import '../features/partnerships/domain/usecases/partnership_usecases.dart';
import 'state/app_state.dart';
import 'middleware/auth_middleware.dart';
import 'middleware/partnership_middleware.dart';
import 'reducers/app_reducer.dart';
import 'state/auth_state.dart';
import 'state/partnerships_state.dart';

/// Builds the application's Redux store after dependencies are registered.
Future<Store<AppState>> createAppStore() async {
  var initialAuth = AuthState.initial();
  try {
    final session = await sl<RestoreSessionUseCase>().call(NoParams());
    if (session != null) {
      initialAuth = AuthState(
        token: session.token,
        role: session.role,
        userName: session.userName,
      );
    }
  } catch (_) {
    // An unreadable stored session is treated as signed out.
  }

  final authMiddleware = AuthMiddleware(
    adminLoginUseCase: sl<AdminLoginUseCase>(),
    verifyAdminOtpUseCase: sl<VerifyAdminOtpUseCase>(),
    authRepository: sl<AuthRepository>(),
  );

  final partnershipMiddleware = PartnershipMiddleware(
    loadPharmacyDirectory: sl<LoadPharmacyDirectoryUseCase>(),
    loadPartnershipOverview: sl<LoadPartnershipOverviewUseCase>(),
    createGroup: sl<CreateGroupUseCase>(),
    updateGroup: sl<UpdateGroupUseCase>(),
    assignPharmacyToGroup: sl<AssignPharmacyToGroupUseCase>(),
    removePharmacyFromGroup: sl<RemovePharmacyFromGroupUseCase>(),
    movePharmacyToGroup: sl<MovePharmacyToGroupUseCase>(),
    createAgreement: sl<CreateAgreementUseCase>(),
    setAgreementStatus: sl<SetAgreementStatusUseCase>(),
  );

  return Store<AppState>(
    appReducer,
    initialState: AppState(
      authState: initialAuth,
      navigationState: AppState.initial().navigationState,
      partnershipsState: PartnershipsState.initial(),
    ),
    middleware: [
      ...authMiddleware.middleware,
      ...partnershipMiddleware.middleware,
    ],
  );
}
