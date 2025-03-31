import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages step counting and statistics
class StepCounter {
  /// Key for storing step data in SharedPreferences
  static const String _storageKey = 'step_counter_data';
  
  /// Daily steps taken
  final int dailySteps;
  
  /// Average steps over time
  final double averageSteps;
  
  /// Last time steps were reset
  final DateTime lastReset;
  
  /// History of daily step counts
  final List<DailyStepCount> history;

  StepCounter({
    required this.dailySteps,
    required this.averageSteps,
    required this.lastReset,
    required this.history,
  });

  /// Creates initial StepCounter state
  factory StepCounter.initial() {
    return StepCounter(
      dailySteps: 0,
      averageSteps: 0,
      lastReset: DateTime.now(),
      history: [],
    );
  }

  /// Adds steps and updates statistics
  StepCounter addSteps(int steps) {
    final now = DateTime.now();
    final newDailySteps = _shouldResetDaily(now) ? steps : dailySteps + steps;
    final newHistory = List<DailyStepCount>.from(history);
    
    // If we should reset, add yesterday's count to history
    if (_shouldResetDaily(now)) {
      if (dailySteps > 0) {
        newHistory.add(DailyStepCount(
          date: lastReset,
          steps: dailySteps,
        ));
      }
    }

    // Calculate new average including today's steps
    final totalDays = newHistory.length + 1; // +1 for today
    final historicalSteps = newHistory.fold<int>(0, (sum, day) => sum + day.steps);
    final newAverage = (historicalSteps + newDailySteps) / totalDays;

    return StepCounter(
      dailySteps: newDailySteps,
      averageSteps: newAverage,
      lastReset: _shouldResetDaily(now) ? now : lastReset,
      history: newHistory,
    );
  }

  /// Checks if daily steps should be reset
  bool _shouldResetDaily(DateTime now) {
    return !lastReset.isAtSameMomentAs(now) &&
        (now.day != lastReset.day || 
         now.month != lastReset.month || 
         now.year != lastReset.year);
  }

  /// Saves state to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(toJson()));
  }

  /// Loads state from SharedPreferences
  static Future<StepCounter> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return StepCounter.initial();
    
    try {
      return StepCounter.fromJson(jsonDecode(data));
    } catch (e) {
      return StepCounter.initial();
    }
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'dailySteps': dailySteps,
      'averageSteps': averageSteps,
      'lastReset': lastReset.toIso8601String(),
      'history': history.map((h) => h.toJson()).toList(),
    };
  }

  /// Creates instance from JSON storage
  factory StepCounter.fromJson(Map<String, dynamic> json) {
    return StepCounter(
      dailySteps: json['dailySteps'] as int,
      averageSteps: (json['averageSteps'] as num).toDouble(),
      lastReset: DateTime.parse(json['lastReset'] as String),
      history: (json['history'] as List)
          .map((h) => DailyStepCount.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Represents a single day's step count
class DailyStepCount {
  final DateTime date;
  final int steps;

  DailyStepCount({
    required this.date,
    required this.steps,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
    };
  }

  factory DailyStepCount.fromJson(Map<String, dynamic> json) {
    return DailyStepCount(
      date: DateTime.parse(json['date'] as String),
      steps: json['steps'] as int,
    );
  }
} 