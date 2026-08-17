import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class VerifyAdminOtpParams {
  final String email;
  final String otpCode;

  const VerifyAdminOtpParams({required this.email, required this.otpCode});
}

/// Exchanges the emailed admin code for a session.
class VerifyAdminOtpUseCase
    implements UseCase<AuthSession, VerifyAdminOtpParams> {
  VerifyAdminOtpUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<AuthSession> call(VerifyAdminOtpParams params) async {
    if (params.email.trim().isEmpty) {
      throw const ValidationFailure('We lost track of your sign-in.');
    }

    // The server issues exactly six digits. Rejecting anything else here stops
    // a mistyped code being logged as a failed attempt, which counts toward
    // the same five-per-hour lockout as a wrong password.
    final code = params.otpCode.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      throw const ValidationFailure('Enter the 6-digit code from your email.');
    }

    return repository.verifyAdminOtp(email: params.email, otpCode: code);
  }
}
