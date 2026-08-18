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
