import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:gati/app/data/models/activity_model.dart';
import 'package:gati/app/data/models/activity_type.dart';
import 'package:gati/app/modules/activity_detail/controllers/activity_detail_controller.dart';

class ActivityDetailView extends GetView<ActivityDetailController> {
  const ActivityDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Activity Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black87),
            tooltip: 'Edit',
            onPressed: () => controller.showEditSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () => controller.confirmDelete(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final activity = controller.activity.value;
        if (activity == null) {
          return Center(child: Text(controller.errorMessage.value));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: activity.type.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      activity.type.icon,
                      size: 16,
                      color: activity.type.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activity.type.label,
                      style: TextStyle(
                        color: activity.type.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Activity title
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (activity.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Map
              _ActivityMap(activity: activity),
              const SizedBox(height: 24),
              // Statistics Section
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _StatisticsGrid(activity: activity),
              const SizedBox(height: 24),
              // Details Section
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _DetailsCard(activity: activity),
            ],
          ),
        );
      }),
    );
  }
}

class _ActivityMap extends StatefulWidget {
  const _ActivityMap({required this.activity});

  final Activity activity;

  @override
  State<_ActivityMap> createState() => _ActivityMapState();
}

class _ActivityMapState extends State<_ActivityMap> {
  final MapController _mapController = MapController();

  void _centerMap() {
    final points = widget.activity.route;
    if (points.isEmpty) return;

    final latLngs = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final bounds = LatLngBounds.fromPoints(latLngs);

    // If all points are the same, fitCamera will fail with infinite zoom.
    // In this case, just move to that point with a default zoom level.
    if (bounds.southWest == bounds.northEast) {
      _mapController.move(bounds.center, 15);
    } else {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.activity.route;
    LatLng center;

    if (points.isNotEmpty) {
      final avgLat =
          points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final avgLng =
          points.map((p) => p.longitude).reduce((a, b) => a + b) /
          points.length;
      center = LatLng(avgLat, avgLng);
    } else {
      center = const LatLng(-6.1751, 106.8650);
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
                onMapReady: () {
                  // Auto fit bounds once map is ready
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _centerMap();
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.example.gati',
                ),
                if (points.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points
                            .map((p) => LatLng(p.latitude, p.longitude))
                            .toList(),
                        strokeWidth: 4,
                        color: const Color(0xFF4DB6AC),
                      ),
                    ],
                  ),
                // Start/End markers
                MarkerLayer(
                  markers: [
                    if (points.isNotEmpty)
                      Marker(
                        point: LatLng(
                          points.first.latitude,
                          points.first.longitude,
                        ),
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                        ),
                      ),
                    if (points.isNotEmpty)
                      Marker(
                        point: LatLng(
                          points.last.latitude,
                          points.last.longitude,
                        ),
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Re-center button
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton.small(
              onPressed: _centerMap,
              backgroundColor: Colors.white,
              elevation: 2,
              heroTag: 'detail_center_map',
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Satellite',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.activity});

  final Activity activity;

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.directions_run,
                label: 'Distance',
                value: activity.distanceKm.toStringAsFixed(2),
                unit: 'km',
                backgroundColor: const Color(0xFFE8F5F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.speed,
                label: 'Avg Pace',
                value: activity.averagePace,
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
              child: _StatCard(
                icon: Icons.timer_outlined,
                label: 'Moving Time',
                value: _formatDuration(activity.duration),
                backgroundColor: Colors.white,
                hasBorder: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.history,
                label: 'Elapsed Time',
                value: _formatDuration(activity.elapsedDuration),
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
              child: _StatCard(
                icon: Icons.terrain,
                label: 'Elev Gain',
                value: activity.elevationGain.toStringAsFixed(0),
                unit: 'm',
                backgroundColor: const Color(0xFFE3F2FD),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.filter_hdr,
                label: 'Max Elev',
                value: activity.maxElevation.toStringAsFixed(0),
                unit: 'm',
                backgroundColor: const Color(0xFFF3E5F5),
              ),
            ),
          ],
        ),
        if (activity.splits.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Splits (min/km)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SplitsChart(activity: activity),
        ],
      ],
    );
  }
}

class _SplitsChart extends StatelessWidget {
  const _SplitsChart({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final splits = activity.splits;
    if (splits.isEmpty) return const SizedBox.shrink();

    // In running, we want to visualize the pace.
    // We'll normalize so the fastest pace (min seconds) gets the longest bar.
    final minPace = splits.reduce((a, b) => a < b ? a : b);
    final maxPace = splits.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('Km', style: _headerStyle)),
                const SizedBox(width: 8),
                SizedBox(width: 60, child: Text('Pace', style: _headerStyle)),
                const SizedBox(width: 8),
                Expanded(child: Text('Performance', style: _headerStyle)),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Split Rows
          ...List.generate(splits.length, (index) {
            final paceSeconds = splits[index];
            final minutes = (paceSeconds / 60).floor();
            final seconds = (paceSeconds % 60).round();
            final paceLabel = '$minutes:${seconds.toString().padLeft(2, '0')}';

            // KM Label logic: handle partial last KM
            String kmLabel = '${index + 1}';
            if (index == splits.length - 1) {
              final totalKm = activity.distanceKm;
              final partial = totalKm - index;
              if (partial > 0 && partial < 0.99) {
                kmLabel = partial.toStringAsFixed(1);
              }
            }

            // Normalize bar width: fastest = 1.0, slowest = 0.3
            double widthFactor;
            if (maxPace == minPace) {
              widthFactor = 1.0;
            } else {
              widthFactor =
                  1.0 - (0.7 * (paceSeconds - minPace) / (maxPace - minPace));
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      kmLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text(
                      paceLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: widthFactor.clamp(0.1, 1.0),
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4DB6AC), Color(0xFF26A69A)],
                            ),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4DB6AC,
                                ).withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.grey[500],
    letterSpacing: 0.5,
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: DateFormat('MMMM d, yyyy').format(activity.startedAt),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Start Time',
            value: DateFormat('hh:mm a').format(activity.startedAt),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
