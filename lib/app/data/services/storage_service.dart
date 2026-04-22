import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

import 'package:gati/app/core/constants/storage_keys.dart';

class StorageService extends GetxService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  GetStorage? _box;

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: StorageKeys.token, value: token);
  }

  Future<String?> readToken() => _secureStorage.read(key: StorageKeys.token);

  Future<void> clearToken() => _secureStorage.delete(key: StorageKeys.token);

  List<Map<String, dynamic>> readUsers() {
    final data = _box?.read(StorageKeys.users);
    if (data == null) {
      return [];
    }
    return (data as List<dynamic>)
        .map((user) => Map<String, dynamic>.from(user as Map))
        .toList();
  }

  Future<void> writeUsers(List<Map<String, dynamic>> users) async {
    await _box?.write(StorageKeys.users, users);
  }

  Map<String, List<Map<String, dynamic>>> _readActivitiesIndex() {
    final data = _box?.read(StorageKeys.activities);
    if (data == null) {
      return {};
    }
    final casted = Map<String, dynamic>.from(data as Map);
    return casted.map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
      ),
    );
  }

  Future<void> _writeActivitiesIndex(
    Map<String, List<Map<String, dynamic>>> data,
  ) async {
    await _box?.write(StorageKeys.activities, data);
  }

  List<Map<String, dynamic>> readActivities(String email) {
    final index = _readActivitiesIndex();
    return index[email]?.toList() ?? [];
  }

  Future<void> writeActivities(
    String email,
    List<Map<String, dynamic>> activities,
  ) async {
    final index = _readActivitiesIndex();
    index[email] = activities;
    await _writeActivitiesIndex(index);
  }

  Future<void> saveCurrentUserEmail(String email) async {
    await _box?.write(StorageKeys.currentUserEmail, email);
  }

  String? readCurrentUserEmail() {
    return _box?.read(StorageKeys.currentUserEmail) as String?;
  }

  Future<void> clearCurrentUserEmail() async {
    await _box?.remove(StorageKeys.currentUserEmail);
  }

  bool isOnboardingCompleted() {
    return _box?.read(StorageKeys.onboardingCompleted) == true;
  }

  Future<void> setOnboardingCompleted() async {
    await _box?.write(StorageKeys.onboardingCompleted, true);
  }
}
