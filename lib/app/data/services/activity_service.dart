import 'package:get/get.dart';

import 'package:gati/app/data/models/activity_model.dart';
import 'package:gati/app/data/services/storage_service.dart';

class ActivityService extends GetxService {
  ActivityService(this._storage);

  final StorageService _storage;

  Future<List<Activity>> fetchActivities(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final stored = _storage.readActivities(email);
    final activities = stored.map(Activity.fromMap).toList();
    activities.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return activities;
  }

  Future<Activity?> findById(String email, String id) async {
    final activities = await fetchActivities(email);
    return activities.firstWhereOrNull((activity) => activity.id == id);
  }

  Future<Activity> saveActivity(Activity activity) async {
    final activities = _storage.readActivities(activity.userEmail);
    final index = activities.indexWhere((item) => item['id'] == activity.id);
    final serialized = activity.toMap();
    if (index >= 0) {
      activities[index] = serialized;
    } else {
      activities.add(serialized);
    }
    await _storage.writeActivities(activity.userEmail, activities);
    return activity;
  }

  Future<void> deleteActivity(String email, String id) async {
    final activities = _storage.readActivities(email);
    activities.removeWhere((item) => item['id'] == id);
    await _storage.writeActivities(email, activities);
  }
}
