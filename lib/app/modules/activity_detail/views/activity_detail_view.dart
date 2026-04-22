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

class _ActivityMap extends StatelessWidget {
  const _ActivityMap({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final points = activity.route;
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
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
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
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.activity});

  final Activity activity;

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.route,
                label: 'Distance',
                value: activity.distanceKm.toStringAsFixed(2),
                unit: 'km',
                backgroundColor: const Color(0xFFE8F5F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.access_time,
                label: 'Duration',
                value: _formatDuration(activity.duration),
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
                icon: Icons.speed,
                label: 'Avg Speed',
                value: activity.averageSpeedKmh.toStringAsFixed(1),
                unit: 'km/h',
                backgroundColor: Colors.white,
                hasBorder: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.speed,
                label: 'Max Speed',
                value: (activity.averageSpeedKmh * 1.3).toStringAsFixed(1),
                unit: 'km/h',
                backgroundColor: const Color(0xFFFFF3E0),
              ),
            ),
          ],
        ),
      ],
    );
  }
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
