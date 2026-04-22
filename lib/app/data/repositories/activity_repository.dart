import 'package:gati/app/data/models/activity_model.dart';
import 'package:gati/app/data/services/activity_service.dart';

class ActivityRepository {
  ActivityRepository(this._service);

  final ActivityService _service;

  Future<List<Activity>> list(String userEmail) {
    return _service.fetchActivities(userEmail);
  }

  Future<Activity?> find(String userEmail, String id) {
    return _service.findById(userEmail, id);
  }

  Future<Activity> save(Activity activity) {
    return _service.saveActivity(activity);
  }

  Future<Activity> update(Activity activity) {
    return _service.saveActivity(activity);
  }

  Future<void> delete(String userEmail, String id) {
    return _service.deleteActivity(userEmail, id);
  }
}
