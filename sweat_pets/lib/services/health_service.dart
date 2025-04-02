import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sweat_pets/services/app_settings.dart';

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
  
  /// Permission handler - must have same length as _types
  static final List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];
  
  /// Print available data types for debugging
  void printAvailableTypes() {
    try {
      debugPrint('🩺 Available HealthDataTypes:');
      for (final field in HealthDataType.values) {
        debugPrint('🩺 - $field');
      }
    } catch (e) {
      debugPrint('🩺 Error printing available types: $e');
    }
  }
  
  /// Initialize and request permissions
  Future<bool> requestPermissions() async {
    // Default to offline mode if not connected
    try {
      debugPrint('🩺 Requesting HealthKit permissions...');
      
      // Verify that types and permissions are the same length (safety check)
      if (_types.length != _permissions.length) {
        debugPrint('🩺 ERROR: Types length (${_types.length}) does not match permissions length (${_permissions.length})');
        return false;
      }
      
      // Request permissions for all types at once
      final requested = await _health.requestAuthorization(_types, permissions: _permissions);
      debugPrint('🩺 HealthKit permissions result: $requested');
      
      if (requested) {
        // Explicitly request each type individually to ensure proper permissions
        for (int i = 0; i < _types.length; i++) {
          final type = _types[i];
          final permission = _permissions[i];
          
          debugPrint('🩺 Requesting specific permission for $type');
          await _health.requestAuthorization([type], permissions: [permission]);
        }
        
        // Also request activity recognition permission on Android
        await Permission.activityRecognition.request();
        
        // Give the system a moment to process the permissions
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Verify permissions were granted
      final hasPermission = await _health.hasPermissions(_types, permissions: _permissions) ?? false;
      debugPrint('🩺 HealthKit permissions verified: $hasPermission');
      
      return requested;
    } catch (e) {
      debugPrint('🩺 Error requesting health permissions: $e');
      return false;
    }
  }
  
  /// Check if permissions are granted
  Future<bool> hasPermissions() async {
    try {
      // Verify that types and permissions are the same length (safety check)
      if (_types.length != _permissions.length) {
        debugPrint('🩺 ERROR: Types length (${_types.length}) does not match permissions length (${_permissions.length})');
        return false;
      }
      
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
    // If in offline mode, return empty metrics immediately
    if (AppSettings.offlineMode) {
      return {
        'steps': 0,
        'flightsClimbed': 0,
        'distanceWalkingRunning': 0.0,
        'isOffline': true
      };
    }
    
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      
      return getHealthMetricsBetween(midnight, now);
    } catch (e) {
      debugPrint('🩺 Error getting health metrics for today: $e');
      return {
        'steps': 0,
        'flightsClimbed': 0,
        'distanceWalkingRunning': 0.0,
        'isOffline': true
      };
    }
  }
  
  /// Get all health metrics between two dates
  Future<Map<String, dynamic>> getHealthMetricsBetween(DateTime start, DateTime end) async {
    final Map<String, dynamic> metrics = {
      'steps': 0,
      'flightsClimbed': 0,
      'distanceWalkingRunning': 0.0,
      'isOffline': false
    };
    
    // If in offline mode, return empty metrics
    if (AppSettings.offlineMode) {
      metrics['isOffline'] = true;
      return metrics;
    }
    
    try {
      // Add a timeout to prevent blocking if Health is not available
      return await Future.any([
        _getHealthMetricsImpl(start, end, metrics),
        Future.delayed(const Duration(seconds: 5), () {
          debugPrint('🩺 Health data fetch timed out');
          metrics['isOffline'] = true;
          return metrics;
        }),
      ]);
    } catch (e) {
      debugPrint('🩺 Error getting health metrics: $e');
      // On error, mark as offline but still return the empty metrics
      metrics['isOffline'] = true;
      return metrics;
    }
  }
  
  /// Implementation of health metrics fetching
  Future<Map<String, dynamic>> _getHealthMetricsImpl(
    DateTime start, 
    DateTime end, 
    Map<String, dynamic> metrics
  ) async {
    // Check permissions and request if needed
    var hasPermission = await hasPermissions();
    if (!hasPermission) {
      debugPrint('🩺 No health permissions, requesting...');
      final granted = await requestPermissions();
      if (!granted) {
        debugPrint('🩺 Health permissions denied');
        metrics['isOffline'] = true;
        return metrics;
      }
      
      // Double-check permissions after request
      hasPermission = await hasPermissions();
      if (!hasPermission) {
        debugPrint('🩺 Still no health permissions after request');
        // Continue anyway as the data fetch might still work
      }
    }
    
    // Get steps using the specialized method for better accuracy
    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      if (steps != null && steps > 0) {
        metrics['steps'] = steps.toInt();
        debugPrint('🩺 Steps from getTotalStepsInInterval: ${steps.toInt()}');
      } else {
        debugPrint('🩺 No steps returned from getTotalStepsInInterval');
      }
    } catch (e) {
      debugPrint('🩺 Error getting total steps: $e - will try with individual data points');
    }
    
    // Get all health data
    debugPrint('🩺 Getting health data for period: ${start.toString()} to ${end.toString()}');
    final data = await _health.getHealthDataFromTypes(start, end, _types);
    
    // Process each data point
    int dataPointCount = 0;
    for (var point in data) {
      dataPointCount++;
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
    
    debugPrint('🩺 Processed $dataPointCount health data points');
    debugPrint('🩺 Health metrics for period: $metrics');
    
    // Return the metrics, explicitly marking as not offline
    metrics['isOffline'] = false;
    return metrics;
  }
  
  /// Get steps for today
  Future<int> getStepsToday() async {
    if (AppSettings.offlineMode) return 0;
    
    try {
      final metrics = await getHealthMetricsToday();
      return metrics['steps'] as int;
    } catch (e) {
      debugPrint('🩺 Error getting steps for today: $e');
      return 0;
    }
  }
  
  /// Get steps for a specific date
  Future<int> getStepsForDate(DateTime date) async {
    if (AppSettings.offlineMode) return 0;
    
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final metrics = await getHealthMetricsBetween(startOfDay, endOfDay);
      return metrics['steps'] as int;
    } catch (e) {
      debugPrint('🩺 Error getting steps for date: $e');
      return 0;
    }
  }
  
  /// Get steps between two dates (legacy method)
  Future<int> getStepsBetween(DateTime start, DateTime end) async {
    if (AppSettings.offlineMode) return 0;
    
    try {
      final metrics = await getHealthMetricsBetween(start, end);
      return metrics['steps'] as int;
    } catch (e) {
      debugPrint('🩺 Error getting steps between dates: $e');
      return 0;
    }
  }
  
  /// Get steps for the past week
  Future<Map<DateTime, int>> getStepsForPastWeek() async {
    if (AppSettings.offlineMode) {
      return {};
    }
    
    final Map<DateTime, int> weeklySteps = {};
    try {
      final now = DateTime.now();
      
      // For each of the past 7 days
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final steps = await getStepsForDate(date);
        
        // Store with date at midnight
        final dayKey = DateTime(date.year, date.month, date.day);
        weeklySteps[dayKey] = steps;
      }
    } catch (e) {
      debugPrint('🩺 Error getting steps for past week: $e');
    }
    
    return weeklySteps;
  }
  
  /// Get flights climbed for today
  Future<int> getFlightsClimbedToday() async {
    if (AppSettings.offlineMode) return 0;
    
    try {
      final metrics = await getHealthMetricsToday();
      return metrics['flightsClimbed'] as int;
    } catch (e) {
      debugPrint('🩺 Error getting flights climbed: $e');
      return 0;
    }
  }
  
  /// Get walking/running distance for today in meters
  Future<double> getDistanceWalkingRunningToday() async {
    if (AppSettings.offlineMode) return 0.0;
    
    try {
      final metrics = await getHealthMetricsToday();
      return metrics['distanceWalkingRunning'] as double;
    } catch (e) {
      debugPrint('🩺 Error getting distance: $e');
      return 0.0;
    }
  }
} 