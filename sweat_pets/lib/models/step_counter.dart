import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as Math;

/// Manages step counting and statistics
class StepCounter {
  /// Key for storing step data in SharedPreferences
  static const String _storageKey = 'step_counter_data';
  
  /// Daily steps taken
  final int dailySteps;
  
  /// Manual steps added today
  final int manualStepsToday;
  
  /// Average steps over time
  final double averageSteps;
  
  /// Last time steps were reset
  final DateTime lastReset;
  
  /// History of daily step counts
  final List<DailyStepCount> history;

  StepCounter({
    required this.dailySteps,
    this.manualStepsToday = 0,
    required this.averageSteps,
    required this.lastReset,
    required this.history,
  });

  /// Creates initial StepCounter state
  factory StepCounter.initial() {
    return StepCounter(
      dailySteps: 0,
      manualStepsToday: 0,
      averageSteps: 0,
      lastReset: DateTime.now(),
      history: [],
    );
  }

  /// Adds steps and updates statistics (includes averaging over the week)
  StepCounter addSteps(int steps) {
    final now = DateTime.now();
    
    // Track manual steps separately
    int newManualStepsToday = _shouldResetDaily(now) ? steps : manualStepsToday + steps;
    
    // Update daily steps with both health and manual
    final newDailySteps = _shouldResetDaily(now) ? steps : dailySteps + steps;
    final newHistory = List<DailyStepCount>.from(history);
    
    // If we should reset, add yesterday's count to history
    if (_shouldResetDaily(now)) {
      if (dailySteps > 0) {
        newHistory.add(DailyStepCount(
          date: lastReset,
          steps: dailySteps,
          manualSteps: manualStepsToday,
        ));
      }
    }

    // Calculate new average, distributing manual steps across the week (7 days)
    final totalDays = Math.min(newHistory.length + 1, 7); // +1 for today, max 7 days
    int historicalSteps = 0;
    
    // Get total steps from history (up to 7 days)
    if (newHistory.isNotEmpty) {
      // Sort by date, newest first
      newHistory.sort((a, b) => b.date.compareTo(a.date));
      
      // Take up to 6 most recent days from history (plus today = 7)
      final recentHistory = newHistory.take(6).toList();
      historicalSteps = recentHistory.fold<int>(0, (sum, day) => sum + day.steps);
    }
    
    // Calculate new average including today's steps and manual steps
    double newAverage = (historicalSteps + newDailySteps) / totalDays;
    
    // Add manual steps distributed evenly across 7 days to the average
    // This effectively "spreads" the manually added steps over the week
    if (steps > 0) {
      double dailyManualContribution = steps / 7; // Distribute evenly over a week
      newAverage += dailyManualContribution;
    }

    return StepCounter(
      dailySteps: newDailySteps,
      manualStepsToday: newManualStepsToday,
      averageSteps: newAverage,
      lastReset: _shouldResetDaily(now) ? now : lastReset,
      history: newHistory,
    );
  }
  
  /// Add steps from health without affecting manual steps
  StepCounter addHealthSteps(int healthSteps) {
    final now = DateTime.now();
    
    // Keep manual steps unchanged
    int newManualStepsToday = _shouldResetDaily(now) ? 0 : manualStepsToday;
    
    // Update daily steps with both health and manual
    final newDailySteps = _shouldResetDaily(now) ? 
                         healthSteps + newManualStepsToday : 
                         healthSteps + manualStepsToday;
    
    final newHistory = List<DailyStepCount>.from(history);
    
    // If we should reset, add yesterday's count to history
    if (_shouldResetDaily(now)) {
      if (dailySteps > 0) {
        newHistory.add(DailyStepCount(
          date: lastReset,
          steps: dailySteps,
          manualSteps: manualStepsToday,
        ));
      }
    }

    // Calculate new average including today's steps
    final totalDays = Math.min(newHistory.length + 1, 7); // +1 for today, max 7 days
    
    // Get total steps from history (up to 7 days)
    int historicalSteps = 0;
    if (newHistory.isNotEmpty) {
      // Sort by date, newest first
      newHistory.sort((a, b) => b.date.compareTo(a.date));
      
      // Take up to 6 most recent days from history (plus today = 7)
      final recentHistory = newHistory.take(6).toList();
      historicalSteps = recentHistory.fold<int>(0, (sum, day) => sum + day.steps);
    }
    
    // Calculate new average including today's total steps
    double newAverage = (historicalSteps + newDailySteps) / totalDays;

    return StepCounter(
      dailySteps: newDailySteps,
      manualStepsToday: newManualStepsToday,
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
      'manualStepsToday': manualStepsToday,
      'averageSteps': averageSteps,
      'lastReset': lastReset.toIso8601String(),
      'history': history.map((h) => h.toJson()).toList(),
    };
  }

  /// Creates instance from JSON storage
  factory StepCounter.fromJson(Map<String, dynamic> json) {
    return StepCounter(
      dailySteps: json['dailySteps'] as int,
      manualStepsToday: json.containsKey('manualStepsToday') ? json['manualStepsToday'] as int : 0,
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
  final int manualSteps;

  DailyStepCount({
    required this.date,
    required this.steps,
    this.manualSteps = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'manualSteps': manualSteps,
    };
  }

  factory DailyStepCount.fromJson(Map<String, dynamic> json) {
    return DailyStepCount(
      date: DateTime.parse(json['date'] as String),
      steps: json['steps'] as int,
      manualSteps: json.containsKey('manualSteps') ? json['manualSteps'] as int : 0,
    );
  }
} 