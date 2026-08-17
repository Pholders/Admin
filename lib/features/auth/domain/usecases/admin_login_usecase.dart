import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class AdminLoginParams {
  final String email;
  final String password;

  const AdminLoginParams({required this.email, required this.password});
}

/// Requests the emailed admin code. Completes with no session by design.
class AdminLoginUseCase implements UseCase<void, AdminLoginParams> {
  AdminLoginUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<void> call(AdminLoginParams params) async {
    // Mirrors the server's own 400 so an empty form never costs a round trip —
    // and, because failed attempts are counted per email regardless of role,
    // never burns one of the five attempts allowed that hour.
    if (params.email.trim().isEmpty || params.password.trim().isEmpty) {
      throw const ValidationFailure();
    }

    return repository.adminLogin(
      email: params.email,
      password: params.password,
    );
  }
}
