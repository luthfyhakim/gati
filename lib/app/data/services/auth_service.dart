import 'dart:convert';

import 'package:get/get.dart';

import 'package:gati/app/core/exceptions/app_exception.dart';
import 'package:gati/app/data/models/user_model.dart';
import 'package:gati/app/data/services/storage_service.dart';

class AuthService extends GetxService {
  AuthService(this._storage);

  final StorageService _storage;

  Future<String> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final users = _storage.readUsers();
    final alreadyExists = users.any((user) => user['email'] == email);
    if (alreadyExists) {
      throw AuthException('Email already registered.');
    }

    final newUser = GatiUser(
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      password: password,
    );

    users.add(newUser.toMap());
    await _storage.writeUsers(users);

    final token = _issueToken(email);
    await _storage.saveToken(token);
    await _storage.saveCurrentUserEmail(email);
    return token;
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final users = _storage.readUsers();
    final normalizedEmail = email.trim().toLowerCase();
    final matched = users.firstWhereOrNull(
      (user) => user['email'] == normalizedEmail,
    );
    if (matched == null || matched['password'] != password) {
      throw AuthException('Invalid email or password.');
    }

    final token = _issueToken(normalizedEmail);
    await _storage.saveToken(token);
    await _storage.saveCurrentUserEmail(normalizedEmail);
    return token;
  }

  Future<void> logout() async {
    await _storage.clearToken();
    await _storage.clearCurrentUserEmail();
  }

  Future<bool> hasActiveSession() async {
    final token = await _storage.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> currentToken() => _storage.readToken();

  String? currentUserEmail() => _storage.readCurrentUserEmail();

  String? currentUserFullName() {
    final email = _storage.readCurrentUserEmail();
    if (email == null) return null;
    final users = _storage.readUsers();
    final user = users.firstWhereOrNull((u) => u['email'] == email);
    return user?['fullName'] as String?;
  }

  String _issueToken(String email) {
    final payload = {
      'email': email,
      'issuedAt': DateTime.now().toIso8601String(),
    };
    return base64Url.encode(utf8.encode(payload.toString()));
  }
}
