import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service that handles health data retrieval
class HealthService {
  /// Health factory instance
  final HealthFactory _health = HealthFactory();
  
  /// Available data types
  static const List<HealthDataType> _types = [HealthDataType.STEPS];
  
  /// Permission handler
  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ
  ];
  
  /// Initialize and request permissions
  Future<bool> requestPermissions() async {
    try {
      // Request health permissions
      final requested = await _health.requestAuthorization(_types, permissions: _permissions);
      
      // Also request activity recognition permission on Android
      if (requested) {
        await Permission.activityRecognition.request();
      }
      
      return requested;
    } catch (e) {
      debugPrint('Error requesting health permissions: $e');
      return false;
    }
  }
  
  /// Check if permissions are granted
  Future<bool> hasPermissions() async {
    try {
      return await _health.hasPermissions(_types, permissions: _permissions) ?? false;
    } catch (e) {
      debugPrint('Error checking health permissions: $e');
      return false;
    }
  }
  
  /// Get steps for today
  Future<int> getStepsToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    
    return await getStepsBetween(midnight, now);
  }
  
  /// Get steps for a specific date
  Future<int> getStepsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return await getStepsBetween(startOfDay, endOfDay);
  }
  
  /// Get steps between two dates
  Future<int> getStepsBetween(DateTime start, DateTime end) async {
    try {
      // Check permissions
      final hasPermission = await hasPermissions();
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) {
          debugPrint('Health permissions not granted');
          return 0;
        }
      }
      
      // Get step data
      final steps = await _health.getTotalStepsInInterval(start, end);
      
      // If null, return 0
      return steps?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Error getting steps: $e');
      return 0;
    }
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
} 