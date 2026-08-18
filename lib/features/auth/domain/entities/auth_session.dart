/// A signed-in session, normalised from whatever shape the API returned.
///
/// Nothing downstream should ever parse an auth response itself — the
/// repository produces this, and widgets read it.
class AuthSession {
  final String token;

  /// Admin is never issued one. Kept on the entity so the field means the same
  /// thing here as in the doctor/pharmacy client.
  final String? refreshToken;

  final String role;
  final String userName;

  const AuthSession({
    required this.token,
    required this.role,
    required this.userName,
    this.refreshToken,
  });
}
