import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service that handles health data retrieval
class HealthService {
  /// Health factory instance
  final HealthFactory _health = HealthFactory();
  
  /// Available data types - verified for health package version 8.1.0
  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
  ];
  
  /// Permission handler
  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ
  ];
  
  /// Print all available data types for debugging
  void printAvailableTypes() {
    debugPrint('🩺 Available HealthDataTypes:');
    for (final field in HealthDataType.values) {
      debugPrint('🩺 - $field');
    }
  }
  
  /// Initialize and request permissions
  Future<bool> requestPermissions() async {
    try {
      debugPrint('🩺 Requesting HealthKit permissions...');
      // The permissions parameter IS needed for iOS
      final requested = await _health.requestAuthorization(_types, permissions: _permissions);
      
      debugPrint('🩺 HealthKit permissions result: $requested');
      
      // Also request activity recognition permission on Android
      if (requested) {
        await Permission.activityRecognition.request();
      }
      
      return requested;
    } catch (e) {
      debugPrint('🩺 Error requesting health permissions: $e');
      return false;
    }
  }
  
  /// Check if permissions are granted
  Future<bool> hasPermissions() async {
    try {
      // The permissions parameter IS needed for iOS
      final hasPermission = await _health.hasPermissions(_types, permissions: _permissions) ?? false;
      debugPrint('🩺 HealthKit permissions status: $hasPermission');
      return hasPermission;
    } catch (e) {
      debugPrint('🩺 Error checking health permissions: $e');
      return false;
    }
  }
  
  /// Get all health metrics for today
  Future<Map<String, dynamic>> getHealthMetricsToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    
    return getHealthMetricsBetween(midnight, now);
  }
  
  /// Get all health metrics between two dates
  Future<Map<String, dynamic>> getHealthMetricsBetween(DateTime start, DateTime end) async {
    final Map<String, dynamic> metrics = {
      'steps': 0,
      'flightsClimbed': 0,
      'distanceWalkingRunning': 0.0,
    };
    
    try {
      // Check permissions
      final hasPermission = await hasPermissions();
      if (!hasPermission) {
        debugPrint('🩺 No health permissions, requesting...');
        final granted = await requestPermissions();
        if (!granted) {
          debugPrint('🩺 Health permissions denied');
          return metrics;
        }
      }
      
      // Get steps using the specialized method for better accuracy
      final steps = await _health.getTotalStepsInInterval(start, end);
      if (steps != null && steps > 0) {
        metrics['steps'] = steps.toInt();
        debugPrint('🩺 Steps from getTotalStepsInInterval: ${steps.toInt()}');
      }
      
      // Get all health data
      debugPrint('🩺 Getting health data for period: ${start.toString()} to ${end.toString()}');
      final data = await _health.getHealthDataFromTypes(start, end, _types);
      
      // Process each data point
      for (var point in data) {
        debugPrint('🩺 Health data point: ${point.type}, ${point.value}');
        if (point.value is NumericHealthValue) {
          final numValue = point.value as NumericHealthValue;
          final value = numValue.numericValue;
          
          switch (point.type) {
            case HealthDataType.FLIGHTS_CLIMBED:
              metrics['flightsClimbed'] += value.toInt();
              break;
            case HealthDataType.DISTANCE_WALKING_RUNNING:
              metrics['distanceWalkingRunning'] += value;
              break;
            case HealthDataType.STEPS:
              // Only use this if the specialized method failed
              if (metrics['steps'] == 0) {
                metrics['steps'] += value.toInt();
              }
              break;
            default:
              break;
          }
        }
      }
      
      debugPrint('🩺 Health metrics for period: $metrics');
      return metrics;
    } catch (e) {
      debugPrint('🩺 Error getting health metrics: $e');
      return metrics;
    }
  }
  
  /// Get steps for today
  Future<int> getStepsToday() async {
    final metrics = await getHealthMetricsToday();
    return metrics['steps'] as int;
  }
  
  /// Get steps for a specific date
  Future<int> getStepsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final metrics = await getHealthMetricsBetween(startOfDay, endOfDay);
    return metrics['steps'] as int;
  }
  
  /// Get steps between two dates (legacy method)
  Future<int> getStepsBetween(DateTime start, DateTime end) async {
    final metrics = await getHealthMetricsBetween(start, end);
    return metrics['steps'] as int;
  }
  
  /// Get steps for the past week
  Future<Map<DateTime, int>> getStepsForPastWeek() async {
    final Map<DateTime, int> weeklySteps = {};
    final now = DateTime.now();
    
    // For each of the past 7 days
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final steps = await getStepsForDate(date);
      
      // Store with date at midnight
      final dayKey = DateTime(date.year, date.month, date.day);
      weeklySteps[dayKey] = steps;
    }
    
    return weeklySteps;
  }
  
  /// Get flights climbed for today
  Future<int> getFlightsClimbedToday() async {
    final metrics = await getHealthMetricsToday();
    return metrics['flightsClimbed'] as int;
  }
  
  /// Get walking/running distance for today in meters
  Future<double> getDistanceWalkingRunningToday() async {
    final metrics = await getHealthMetricsToday();
    return metrics['distanceWalkingRunning'] as double;
  }
} 