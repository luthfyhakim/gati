import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:gati/app/data/models/activity_model.dart';
import 'package:gati/app/data/repositories/activity_repository.dart';
import 'package:gati/app/data/repositories/auth_repository.dart';
import 'package:gati/app/routes/app_pages.dart';

class ActivityDetailController extends GetxController {
  ActivityDetailController(this._activityRepository, this._authRepository);

  final ActivityRepository _activityRepository;
  final AuthRepository _authRepository;

  final Rx<Activity?> activity = Rx<Activity?>(null);
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  /// Text controllers for the edit bottom sheet.
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? _userEmail;
  late final String? _activityId;

  @override
  void onInit() {
    super.onInit();
    _userEmail = _authRepository.currentUserEmail();
    _activityId = Get.arguments as String?;
  }

  @override
  void onReady() {
    super.onReady();
    if (_userEmail == null) {
      Get.offAllNamed(Routes.login);
      return;
    }
    if (_activityId == null) {
      errorMessage.value = 'Missing activity identifier';
      isLoading.value = false;
      return;
    }
    loadActivity();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> loadActivity() async {
    try {
      isLoading.value = true;
      final data = await _activityRepository.find(_userEmail!, _activityId!);
      activity.value = data;
      errorMessage.value = data == null ? 'Activity not found' : '';
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Shows the edit bottom sheet pre-filled with the current values.
  void showEditSheet() {
    final current = activity.value;
    if (current == null) return;

    nameController.text = current.title;
    descriptionController.text = current.description;

    Get.bottomSheet(
      _buildEditSheet(),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _buildEditSheet() {
    const primaryColor = Color(0xFF4DB6AC);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: Get.mediaQuery.viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Update the name or description of your activity',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            // Name field
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Activity Name *',
                hintText: 'e.g. Morning Run',
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Description field
            TextFormField(
              controller: descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'How was your run?',
                prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveEdit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEdit() async {
    final current = activity.value;
    if (current == null) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Name required',
        'Please enter a name for your activity',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final updated = current.copyWith(
        title: name,
        description: descriptionController.text.trim(),
      );
      await _activityRepository.update(updated);
      activity.value = updated;
      Get.back(); // Close bottom sheet
      Get.snackbar('Updated', 'Activity updated successfully.');
    } catch (error) {
      Get.snackbar('Error', 'Failed to update activity');
    }
  }

  /// Shows a confirmation dialog then deletes the activity.
  void confirmDelete() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Activity',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to delete this activity? This action cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _deleteActivity(),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteActivity() async {
    if (_userEmail == null || _activityId == null) return;

    try {
      await _activityRepository.delete(_userEmail!, _activityId);
      Get.back(); // Close dialog
      Get.back(); // Go back to history list
      Get.snackbar('Deleted', 'Activity deleted successfully.');
    } catch (error) {
      Get.back(); // Close dialog
      Get.snackbar('Error', 'Failed to delete activity');
    }
  }
}
