abstract class Failure implements Exception {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Unable to reach the server'])
      : super(message);
}

/// The server rejected the bearer token (HTTP 401): it expired, was revoked by
/// a logout elsewhere, or was never valid. The session cannot be recovered —
/// admin tokens have no refresh token — so the only way on is to sign in again.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(
      [String message = 'Your session has expired. Please sign in again.'])
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Unable to save the session locally'])
      : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Please provide valid credentials'])
      : super(message);
}
