import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:gati/app/data/models/activity_point.dart';
import 'package:gati/app/data/models/activity_type.dart';
import 'package:gati/app/modules/tracking/controllers/tracking_controller.dart';

class TrackingView extends GetView<TrackingController> {
  const TrackingView({super.key});

  static const Color _accentColor = Color(0xFFFF7043);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          // Show activity complete screen if tracking just stopped
          if (controller.showComplete.value) {
            return _ActivityCompleteView(controller: controller);
          }

          return Stack(
            children: [
              // Full screen map
              Positioned.fill(
                child: _FullScreenMap(
                  points: controller.points.toList(),
                  isTracking: controller.isTracking.value,
                  initialPosition: controller.initialPosition.value,
                ),
              ),
              // Back button
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                    color: Colors.black87,
                  ),
                ),
              ),
              // Activity type and Recording badge
              Positioned(
                top: 8,
                right: 16,
                child: Row(
                  children: [
                    // Activity type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: controller.selectedType.value.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.selectedType.value.icon,
                            color: controller.selectedType.value.color,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            controller.selectedType.value.label,
                            style: TextStyle(
                              color: controller.selectedType.value.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isTracking.value) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Recording',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Bottom panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomPanel(controller: controller),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _FullScreenMap extends StatelessWidget {
  const _FullScreenMap({
    required this.points,
    required this.isTracking,
    required this.initialPosition,
  });

  final List<ActivityPoint> points;
  final bool isTracking;
  final Position? initialPosition;

  static const Color _primaryColor = Color(0xFF4DB6AC);
  static const Color _accentColor = Color(0xFFFF7043);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: initialPosition != null
            ? LatLng(initialPosition!.latitude, initialPosition!.longitude)
            : const LatLng(-6.1751, 106.8650),
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.gati',
        ),
        // Route polyline
        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
                strokeWidth: 4,
                color: _primaryColor,
              ),
            ],
          ),
        // Markers
        MarkerLayer(
          markers: [
            // Start marker (green)
            if (points.isNotEmpty)
              Marker(
                point: LatLng(points.first.latitude, points.first.longitude),
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 3),
                  ),
                ),
              ),
            // Current position marker
            if (points.isNotEmpty)
              Marker(
                point: LatLng(points.last.latitude, points.last.longitude),
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: isTracking ? _accentColor : _primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            // Default marker when no points
            if (points.isEmpty && initialPosition != null)
              Marker(
                point: LatLng(
                  initialPosition!.latitude,
                  initialPosition!.longitude,
                ),
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          _StatsRow(controller: controller),
          const SizedBox(height: 24),
          // Action buttons
          _ActionButtons(controller: controller),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            icon: Icons.directions_run,
            value: controller.formattedDistance,
            label: 'km',
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _StatItem(
            icon: Icons.access_time,
            value: controller.formattedDurationShort,
            label: 'duration',
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _StatItem(
            icon: Icons.speed,
            value: controller.formattedPace,
            label: 'km/h',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.controller});

  final TrackingController controller;

  static const Color _accentColor = Color(0xFFFF7043);
  static const Color _activeColor = Color(0xFF4DB6AC);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isTracking.value) {
        // Not tracking - show start button
        return GestureDetector(
          onTap: () => controller.startTracking(),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
          ),
        );
      }

      // Tracking - show pause and stop buttons
      final pauseButtonColor = controller.isPaused.value
          ? _accentColor
          : _activeColor;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pause button
          GestureDetector(
            onTap: () => controller.togglePause(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: pauseButtonColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: pauseButtonColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                controller.isPaused.value ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Stop button
          GestureDetector(
            onTap: () => controller.stopTracking(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 32),
            ),
          ),
        ],
      );
    });
  }
}

// Activity Complete Screen
class _ActivityCompleteView extends StatelessWidget {
  const _ActivityCompleteView({required this.controller});

  final TrackingController controller;

  static const Color _primaryColor = Color(0xFF4DB6AC);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Activity type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: controller.selectedType.value.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    controller.selectedType.value.icon,
                    color: controller.selectedType.value.color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    controller.selectedType.value.label,
                    style: TextStyle(
                      color: controller.selectedType.value.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Checkmark icon
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Run Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great job on your run',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            // Map preview
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _MiniMap(points: controller.completedPoints),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'GPS Map',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Activity Summary label
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Activity Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Summary grid
            _SummaryGrid(controller: controller),
            const SizedBox(height: 24),
            // ── Name & Description input fields ──
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Activity Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name field
            TextFormField(
              controller: controller.nameController,
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
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
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
              controller: controller.descriptionController,
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
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.discardActivity(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : () => controller.saveActivity(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Save Activity'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.points});

  final List<ActivityPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(color: Colors.grey[200]);
    }

    final center = LatLng(
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
      points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(flags: 0),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.gati',
        ),
        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
                strokeWidth: 3,
                color: const Color(0xFF4DB6AC),
              ),
            ],
          ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.directions_run,
                label: 'Distance',
                value: controller.completedDistance,
                unit: 'km',
                backgroundColor: const Color(0xFFE8F5F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.access_time,
                label: 'Duration',
                value: controller.completedDuration,
                backgroundColor: Colors.white,
                hasBorder: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.speed,
                label: 'Avg Speed',
                value: controller.completedSpeed,
                unit: 'km/h',
                backgroundColor: Colors.white,
                hasBorder: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.calendar_today,
                label: 'Date',
                value: controller.completedDate,
                backgroundColor: Colors.white,
                hasBorder: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    required this.backgroundColor,
    this.hasBorder = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Color backgroundColor;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: hasBorder ? Border.all(color: Colors.grey[200]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
