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

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Unable to save the session locally'])
      : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Please provide valid credentials'])
      : super(message);
}

/// The stored token was rejected by the API.
///
/// Separate from [ServerFailure] because the only recovery is to sign in
/// again — middleware turns this into a `SessionExpiredAction`, which routes
/// the admin back to the login page.
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure(
      [String message = 'Your session has expired. Please sign in again.'])
      : super(message);
}
