import 'package:gati/app/data/services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;

  Future<String> login({required String email, required String password}) {
    return _service.login(email: email, password: password);
  }

  Future<String> register({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _service.register(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  Future<void> logout() => _service.logout();

  Future<bool> hasActiveSession() => _service.hasActiveSession();

  String? currentUserEmail() => _service.currentUserEmail();

  String? currentUserFullName() => _service.currentUserFullName();

  Future<String?> currentToken() => _service.currentToken();
}
