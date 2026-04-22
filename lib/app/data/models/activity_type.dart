import 'package:flutter/material.dart';

/// The app only supports running activities.
enum ActivityType { run }

extension ActivityTypeX on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.run:
        return 'Running';
    }
  }

  String get apiValue {
    switch (this) {
      case ActivityType.run:
        return 'running';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.run:
        return Icons.directions_run;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.run:
        return const Color(0xFF4DB6AC);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ActivityType.run:
        return const Color(0xFFE0F2F1);
    }
  }

  /// Any unknown value stored in persistence defaults to [ActivityType.run].
  static ActivityType fromApiValue(String value) {
    return ActivityType.run;
  }
}
