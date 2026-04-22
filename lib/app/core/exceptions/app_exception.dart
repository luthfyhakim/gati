class AppException implements Exception {
  AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  AuthException(super.message);
}

class PermissionException extends AppException {
  PermissionException(super.message);
}
