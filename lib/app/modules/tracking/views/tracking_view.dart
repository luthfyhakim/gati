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
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return Positioned.fill(
                    child: _FullScreenMap(
                      points: controller.points.toList(),
                      isTracking: controller.isTracking.value,
                      initialPosition: controller.initialPosition.value,
                      mapController: controller.mapController,
                      onMapEvent: controller.onMapEvent,
                      onCenterPressed: () => controller.centerMap(),
                      isAutoTracking: controller.isAutoTracking.value,
                      controller: controller,
                    ),
                  );
                }
              }),
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
    required this.mapController,
    required this.onMapEvent,
    required this.onCenterPressed,
    required this.isAutoTracking,
    required this.controller,
  });

  final List<ActivityPoint> points;
  final bool isTracking;
  final Position? initialPosition;
  final MapController mapController;
  final Function(MapEvent) onMapEvent;
  final VoidCallback onCenterPressed;
  final bool isAutoTracking;
  final TrackingController controller;

  static const Color _primaryColor = Color(0xFF4DB6AC);
  static const Color _accentColor = Color(0xFFFF7043);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: initialPosition != null
                ? LatLng(initialPosition!.latitude, initialPosition!.longitude)
                : const LatLng(0, 0),
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
            onMapEvent: onMapEvent,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
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
                    point: LatLng(
                      points.first.latitude,
                      points.first.longitude,
                    ),
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
        ),
        // Map Controls (Right Side)
        Obx(
          () => AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: controller.isSplitsExpanded.value ? 400 : 260,
            right: 16,
            child: _MapControlButton(
              icon: Icons.my_location,
              onPressed: onCenterPressed,
              isActive: isAutoTracking,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isActive;

  const _MapControlButton({
    this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: _FullScreenMap._primaryColor, size: 24),
          ),
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
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          // Swipe up
          if (details.primaryVelocity! < -300) {
            controller.isSplitsExpanded.value = true;
          }
          // Swipe down
          else if (details.primaryVelocity! > 300) {
            controller.isSplitsExpanded.value = false;
          }
        }
      },
      child: Obx(
        () => Container(
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

              // Expandable Section
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: controller.isSplitsExpanded.value
                    ? Column(
                        children: [
                          const SizedBox(height: 32),
                          _TrackingSplitsView(controller: controller),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),
              // Action buttons
              _ActionButtons(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingSplitsView extends StatelessWidget {
  final TrackingController controller;
  const _TrackingSplitsView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final splits = controller.displaySplits;
          // Calculate the starting KM index for the current view
          final totalCount = controller.isTracking.value
              ? controller.splits.length + 1
              : controller.splits.length;
          final startKm = totalCount > 5 ? totalCount - 4 : 1;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: splits.asMap().entries.map((entry) {
              final index = entry.key;
              final paceSeconds = entry.value;

              final lastDataIndex = splits.lastIndexWhere((s) => s > 0);
              final isActive = paceSeconds > 0 && index == lastDataIndex;

              return _SplitBar(
                paceSeconds: paceSeconds,
                isActive: isActive,
                kmLabel: '${startKm + index}',
              );
            }).toList(),
          );
        }),
        const SizedBox(height: 12),
        const Text(
          'Splits (/km)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _SplitBar extends StatelessWidget {
  final double paceSeconds;
  final bool isActive;
  final String kmLabel;

  const _SplitBar({
    required this.paceSeconds,
    required this.isActive,
    required this.kmLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = paceSeconds > 0;

    String paceText = "";
    if (hasData) {
      final minutes = (paceSeconds / 60).floor();
      final seconds = (paceSeconds % 60).round();
      paceText = '$minutes:${seconds.toString().padLeft(2, '0')}';
    }

    final Color primaryColor = const Color(0xFF4DB6AC);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 16,
            child: Text(
              paceText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: hasData ? Colors.black87 : Colors.transparent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 16,
            width: 48,
            decoration: BoxDecoration(
              color: hasData
                  ? (isActive
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.5))
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kmLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: hasData ? Colors.grey[600] : Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitsBarChart extends StatelessWidget {
  const _SplitsBarChart({required this.splits});
  final List<double> splits;

  @override
  Widget build(BuildContext context) {
    if (splits.isEmpty) return const SizedBox.shrink();

    // Find min/max for scaling
    final minPace = splits.reduce((a, b) => a < b ? a : b);
    final maxPace = splits.reduce((a, b) => a > b ? a : b);
    final range = (maxPace - minPace).abs();
    final scale = range > 0 ? 40.0 / range : 1.0;

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: splits.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final paceSeconds = splits[index];
          final minutes = (paceSeconds / 60).floor();
          final seconds = (paceSeconds % 60).round();
          final paceLabel = '$minutes:${seconds.toString().padLeft(2, '0')}';

          // Normalized height (between 30 and 70)
          final barHeight = range > 0
              ? 30 + ((paceSeconds - minPace) * scale)
              : 50.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                paceLabel,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: barHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          );
        },
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(
            icon: Icons.access_time,
            value: controller.formattedDurationShort,
            label: 'Time',
          ),
          _StatItem(
            icon: Icons.speed,
            value: controller.formattedSplitPace,
            label: 'Split avg. (/km)',
          ),
          _StatItem(
            icon: Icons.directions_run,
            value: controller.formattedDistance,
            label: 'Dist (km)',
          ),
          _StatItem(
            icon: Icons.terrain,
            value: controller.formattedElevationGain,
            label: 'Gain (m)',
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
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.controller});

  final TrackingController controller;

  static const Color _accentColor = Color(0xFFFF7043);

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

      // Tracking - conditional button layout
      if (!controller.isPaused.value) {
        // Just show Pause button when running
        return GestureDetector(
          onTap: () => controller.togglePause(),
          child: Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pause, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text(
                  'Pause',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Show Resume and Finish buttons when paused
      return Row(
        children: [
          // Resume button
          Expanded(
            child: GestureDetector(
              onTap: () => controller.togglePause(),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Resume',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Finish button
          Expanded(
            child: GestureDetector(
              onTap: () => controller.stopTracking(),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop, color: Colors.black87, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Finish',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
            _SummaryGrid(controller: controller),
            const SizedBox(height: 24),
            // Splits chart
            Obx(() {
              final splits = controller.splits;
              if (splits.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Splits (min/km)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SplitsBarChart(splits: splits),
                ],
              );
            }),
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
          urlTemplate: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
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
                icon: Icons.speed,
                label: 'Avg Pace',
                value: controller.completedPace,
                unit: '/km',
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
                icon: Icons.timer_outlined,
                label: 'Moving Time',
                value: controller.completedDuration,
                backgroundColor: Colors.white,
                hasBorder: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.terrain,
                label: 'Elev Gain',
                value: controller.completedElevationGain,
                unit: 'm',
                backgroundColor: const Color(0xFFE3F2FD),
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
