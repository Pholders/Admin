import '../../../../core/usecases/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Reloads a stored session on app start, so a browser refresh does not sign
/// the admin out.
class RestoreSessionUseCase implements UseCase<AuthSession?, NoParams> {
  RestoreSessionUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<AuthSession?> call(NoParams params) => repository.restoreSession();
}
