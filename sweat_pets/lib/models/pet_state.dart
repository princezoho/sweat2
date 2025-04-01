import 'dart:convert';
import 'package:sweat_pets/models/evolution_system.dart';

/// Represents the current state of a pet in the game
class PetState {
  /// Total accumulated steps
  final int totalSteps;
  
  /// Current evolution level of the pet
  final int currentLevel;
  
  /// Current daily steps
  final int dailySteps;
  
  /// Average steps over 7 days
  final double averageSteps;
  
  /// Average level based on 7-day average
  final int averageLevel;
  
  /// Timestamp of last user activity
  final DateTime lastActive;
  
  /// History of daily steps for the past 7 days, keyed by date
  final Map<String, int> dailyStepsHistory;
  
  /// List of unlocked achievements
  final List<String> achievements;

  /// Creates a new PetState instance
  PetState({
    required this.totalSteps,
    required this.currentLevel,
    required this.dailySteps,
    required this.averageSteps,
    required this.averageLevel,
    required this.lastActive,
    required this.dailyStepsHistory,
    required this.achievements,
  });

  /// Creates a default PetState with initial values
  factory PetState.initial() {
    return PetState(
      totalSteps: 0,
      currentLevel: 0,
      dailySteps: 0,
      averageSteps: 0,
      averageLevel: 0,
      lastActive: DateTime.now(),
      dailyStepsHistory: {},
      achievements: [],
    );
  }

  /// Creates a PetState from JSON
  factory PetState.fromJson(Map<String, dynamic> json) {
    Map<String, int> history = {};
    if (json['dailyStepsHistory'] != null) {
      final historyMap = json['dailyStepsHistory'] as Map<String, dynamic>;
      history = historyMap.map((key, value) => MapEntry(key, value as int));
    }
    
    return PetState(
      totalSteps: json['totalSteps'] as int,
      currentLevel: json['currentLevel'] as int,
      dailySteps: json['dailySteps'] as int? ?? 0,
      averageSteps: (json['averageSteps'] as num?)?.toDouble() ?? 0.0,
      averageLevel: json['averageLevel'] as int? ?? 0,
      lastActive: DateTime.parse(json['lastReset'] as String),
      dailyStepsHistory: history,
      achievements: List<String>.from(json['achievements'] as List? ?? []),
    );
  }

  /// Converts PetState to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalSteps': totalSteps,
      'currentLevel': currentLevel,
      'dailySteps': dailySteps,
      'averageSteps': averageSteps,
      'averageLevel': averageLevel,
      'lastReset': lastActive.toIso8601String(),
      'dailyStepsHistory': dailyStepsHistory,
      'achievements': achievements,
    };
  }

  /// Creates a copy of PetState with optional new values
  PetState copyWith({
    int? totalSteps,
    int? currentLevel,
    int? dailySteps,
    double? averageSteps,
    int? averageLevel,
    DateTime? lastActive,
    Map<String, int>? dailyStepsHistory,
    List<String>? achievements,
  }) {
    return PetState(
      totalSteps: totalSteps ?? this.totalSteps,
      currentLevel: currentLevel ?? this.currentLevel,
      dailySteps: dailySteps ?? this.dailySteps,
      averageSteps: averageSteps ?? this.averageSteps,
      averageLevel: averageLevel ?? this.averageLevel,
      lastActive: lastActive ?? this.lastActive,
      dailyStepsHistory: dailyStepsHistory ?? Map<String, int>.from(this.dailyStepsHistory),
      achievements: achievements ?? List<String>.from(this.achievements),
    );
  }

  /// Adds steps and updates level based on evolution system
  PetState addSteps(int steps) {
    final now = DateTime.now();
    final String todayKey = _dateToKey(now);
    
    // Check if it's a new day, reset daily steps if needed
    final bool isNewDay = now.day != lastActive.day || 
                          now.month != lastActive.month || 
                          now.year != lastActive.year;
    
    final int newDailySteps = isNewDay ? steps : dailySteps + steps;
    final int newTotalSteps = totalSteps + steps;
    
    // Update daily steps history
    Map<String, int> updatedHistory = Map<String, int>.from(dailyStepsHistory);
    updatedHistory[todayKey] = newDailySteps;
    
    // Clean history to keep only last 7 days
    _cleanHistory(updatedHistory);
    
    // Calculate new 7-day average
    final double newAverageSteps = _calculateAverageSteps(updatedHistory);
    
    // Calculate evolution levels
    final int dailyLevel = EvolutionSystem.calculateDailyLevel(newDailySteps);
    final int avgLevel = EvolutionSystem.calculateAverageLevel(newAverageSteps);
    
    return copyWith(
      totalSteps: newTotalSteps,
      currentLevel: dailyLevel,
      dailySteps: newDailySteps,
      averageSteps: newAverageSteps,
      averageLevel: avgLevel,
      lastActive: now,
      dailyStepsHistory: updatedHistory,
    );
  }
  
  /// Removes steps (can't go below zero)
  PetState removeSteps(int steps) {
    final now = DateTime.now();
    final String todayKey = _dateToKey(now);
    
    // Ensure we don't go negative
    final int stepsToRemove = steps.abs();
    final int newDailySteps = dailySteps > stepsToRemove ? dailySteps - stepsToRemove : 0;
    final int newTotalSteps = totalSteps > stepsToRemove ? totalSteps - stepsToRemove : totalSteps;
    
    // Update daily steps history
    Map<String, int> updatedHistory = Map<String, int>.from(dailyStepsHistory);
    updatedHistory[todayKey] = newDailySteps;
    
    // Calculate new 7-day average
    final double newAverageSteps = _calculateAverageSteps(updatedHistory);
    
    // Calculate evolution levels
    final int dailyLevel = EvolutionSystem.calculateDailyLevel(newDailySteps);
    final int avgLevel = EvolutionSystem.calculateAverageLevel(newAverageSteps);
    
    return copyWith(
      totalSteps: newTotalSteps,
      currentLevel: dailyLevel,
      dailySteps: newDailySteps,
      averageSteps: newAverageSteps,
      averageLevel: avgLevel,
      lastActive: now,
      dailyStepsHistory: updatedHistory,
    );
  }
  
  /// Resets daily steps to zero but keeps total steps and history
  PetState resetDailySteps() {
    final now = DateTime.now();
    final String todayKey = _dateToKey(now);
    
    // Update daily steps history
    Map<String, int> updatedHistory = Map<String, int>.from(dailyStepsHistory);
    updatedHistory[todayKey] = 0;
    
    // Calculate new 7-day average
    final double newAverageSteps = _calculateAverageSteps(updatedHistory);
    
    // Calculate evolution levels
    final int dailyLevel = 0; // Reset to level 0
    final int avgLevel = EvolutionSystem.calculateAverageLevel(newAverageSteps);
    
    return copyWith(
      currentLevel: dailyLevel,
      dailySteps: 0,
      averageSteps: newAverageSteps,
      averageLevel: avgLevel,
      lastActive: now,
      dailyStepsHistory: updatedHistory,
    );
  }
  
  /// Completely resets the pet to initial state
  factory PetState.reset() {
    return PetState.initial();
  }
  
  /// Calculate average steps from the daily history
  double _calculateAverageSteps(Map<String, int> history) {
    if (history.isEmpty) return 0.0;
    
    int total = 0;
    for (final steps in history.values) {
      total += steps;
    }
    
    return total / history.length;
  }
  
  /// Clean history to keep only the last 7 days
  void _cleanHistory(Map<String, int> history) {
    if (history.length <= 7) return;
    
    List<String> dateKeys = history.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending
    
    // Keep only the last 7 days
    List<String> keysToRemove = dateKeys.sublist(7);
    for (final key in keysToRemove) {
      history.remove(key);
    }
  }
  
  /// Convert date to string key
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Calculates progress to next level for daily pet
  double getProgressToNextLevel() {
    return EvolutionSystem.getProgressToNextLevel(currentLevel, dailySteps);
  }
  
  /// Calculates progress to next level for average pet
  double getAverageProgressToNextLevel() {
    return EvolutionSystem.getProgressToNextLevel(averageLevel, averageSteps.toInt());
  }

  /// Gets the next level threshold for daily pet
  int getNextLevelThreshold() {
    return EvolutionSystem.getNextThreshold(currentLevel);
  }
  
  /// Gets the next level threshold for average pet
  int getAverageNextLevelThreshold() {
    return EvolutionSystem.getNextThreshold(averageLevel);
  }

  /// Checks if pet will evolve with these steps
  bool willEvolveWith(int steps) {
    final newState = addSteps(steps);
    return EvolutionSystem.willEvolve(currentLevel, newState.currentLevel);
  }

  /// Checks if pet has evolved after adding steps
  bool hasEvolved(PetState previousState) {
    return EvolutionSystem.willEvolve(previousState.currentLevel, currentLevel);
  }

  /// Adds steps from manual input (affects daily and 1/7th to average)
  PetState addManualSteps(int steps) {
    final now = DateTime.now();
    final String todayKey = _dateToKey(now);
    
    // Check if it's a new day, reset daily steps if needed
    final bool isNewDay = now.day != lastActive.day || 
                          now.month != lastActive.month || 
                          now.year != lastActive.year;
    
    final int newDailySteps = isNewDay ? steps : dailySteps + steps;
    final int newTotalSteps = totalSteps + steps;
    
    // Update daily steps history
    Map<String, int> updatedHistory = Map<String, int>.from(dailyStepsHistory);
    updatedHistory[todayKey] = newDailySteps;
    
    // Clean history to keep only last 7 days
    _cleanHistory(updatedHistory);
    
    // When manually adding steps, only add 1/7th to weekly average
    // This prevents manual additions from having too much impact
    final double manualAverageContribution = steps / 7.0;
    final double newAverageSteps = averageSteps + manualAverageContribution;
    
    // Calculate evolution levels
    final int dailyLevel = EvolutionSystem.calculateDailyLevel(newDailySteps);
    final int avgLevel = EvolutionSystem.calculateAverageLevel(newAverageSteps);
    
    return copyWith(
      totalSteps: newTotalSteps,
      currentLevel: dailyLevel,
      dailySteps: newDailySteps,
      averageSteps: newAverageSteps,
      averageLevel: avgLevel,
      lastActive: now,
      dailyStepsHistory: updatedHistory,
    );
  }

  @override
  String toString() {
    return 'PetState(totalSteps: $totalSteps, currentLevel: $currentLevel, dailySteps: $dailySteps, averageSteps: $averageSteps, averageLevel: $averageLevel, lastActive: $lastActive, history: ${dailyStepsHistory.length} days, achievements: $achievements)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetState &&
        other.totalSteps == totalSteps &&
        other.currentLevel == currentLevel &&
        other.dailySteps == dailySteps &&
        other.averageSteps == averageSteps &&
        other.averageLevel == averageLevel &&
        other.lastActive.isAtSameMomentAs(lastActive) &&
        mapEquals(other.dailyStepsHistory, dailyStepsHistory) &&
        listEquals(other.achievements, achievements);
  }

  @override
  int get hashCode {
    return Object.hash(
      totalSteps,
      currentLevel,
      dailySteps,
      averageSteps,
      averageLevel,
      lastActive,
      Object.hashAll(dailyStepsHistory.entries),
      Object.hashAll(achievements),
    );
  }
}

/// Helper function to compare lists
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Helper function to compare maps
bool mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
} 