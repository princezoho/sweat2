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
  
  /// Average steps over time
  final double averageSteps;
  
  /// Timestamp of last user activity
  final DateTime lastActive;
  
  /// List of unlocked achievements
  final List<String> achievements;

  /// Creates a new PetState instance
  PetState({
    required this.totalSteps,
    required this.currentLevel,
    required this.dailySteps,
    required this.averageSteps,
    required this.lastActive,
    required this.achievements,
  });

  /// Creates a default PetState with initial values
  factory PetState.initial() {
    return PetState(
      totalSteps: 0,
      currentLevel: 0,
      dailySteps: 0,
      averageSteps: 0,
      lastActive: DateTime.now(),
      achievements: [],
    );
  }

  /// Creates a PetState from JSON
  factory PetState.fromJson(Map<String, dynamic> json) {
    return PetState(
      totalSteps: json['totalSteps'] as int,
      currentLevel: json['currentLevel'] as int,
      dailySteps: json['dailySteps'] as int? ?? 0,
      averageSteps: (json['averageSteps'] as num?)?.toDouble() ?? 0.0,
      lastActive: DateTime.parse(json['lastReset'] as String),
      achievements: List<String>.from(json['achievements'] as List),
    );
  }

  /// Converts PetState to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalSteps': totalSteps,
      'currentLevel': currentLevel,
      'dailySteps': dailySteps,
      'averageSteps': averageSteps,
      'lastReset': lastActive.toIso8601String(),
      'achievements': achievements,
    };
  }

  /// Creates a copy of PetState with optional new values
  PetState copyWith({
    int? totalSteps,
    int? currentLevel,
    int? dailySteps,
    double? averageSteps,
    DateTime? lastActive,
    List<String>? achievements,
  }) {
    return PetState(
      totalSteps: totalSteps ?? this.totalSteps,
      currentLevel: currentLevel ?? this.currentLevel,
      dailySteps: dailySteps ?? this.dailySteps,
      averageSteps: averageSteps ?? this.averageSteps,
      lastActive: lastActive ?? this.lastActive,
      achievements: achievements ?? List<String>.from(this.achievements),
    );
  }

  /// Adds steps and updates level based on evolution system
  PetState addSteps(int steps) {
    final now = DateTime.now();
    
    // Check if it's a new day, reset daily steps if needed
    final bool isNewDay = now.day != lastActive.day || 
                          now.month != lastActive.month || 
                          now.year != lastActive.year;
    
    final int newDailySteps = isNewDay ? steps : dailySteps + steps;
    final int newTotalSteps = totalSteps + steps;
    
    // Calculate new average (simplified for demo purposes)
    // In a real app, we'd track a history of daily steps for accurate average
    final double newAverageSteps = (averageSteps == 0) 
        ? newDailySteps.toDouble()  // First time adding steps
        : isNewDay
            ? (averageSteps + newDailySteps) / 2  // New day, average with previous
            : (averageSteps + newDailySteps) / 2;  // Same day, re-average
    
    // Calculate evolution levels
    final int dailyLevel = EvolutionSystem.calculateDailyLevel(newDailySteps);
    final int avgLevel = EvolutionSystem.calculateAverageLevel(newAverageSteps);
    
    // For simplicity in testing, use the daily level for current level
    // In a real app, this could be more sophisticated
    final int newLevel = dailyLevel;
    
    return copyWith(
      totalSteps: newTotalSteps,
      currentLevel: newLevel,
      dailySteps: newDailySteps,
      averageSteps: newAverageSteps,
      lastActive: now,
    );
  }

  /// Calculates progress to next level
  double getProgressToNextLevel() {
    return EvolutionSystem.getProgressToNextLevel(currentLevel, dailySteps);
  }

  /// Gets the next level threshold
  int getNextLevelThreshold() {
    return EvolutionSystem.getNextThreshold(currentLevel);
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

  @override
  String toString() {
    return 'PetState(totalSteps: $totalSteps, currentLevel: $currentLevel, dailySteps: $dailySteps, averageSteps: $averageSteps, lastActive: $lastActive, achievements: $achievements)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetState &&
        other.totalSteps == totalSteps &&
        other.currentLevel == currentLevel &&
        other.dailySteps == dailySteps &&
        other.averageSteps == averageSteps &&
        other.lastActive.isAtSameMomentAs(lastActive) &&
        listEquals(other.achievements, achievements);
  }

  @override
  int get hashCode {
    return Object.hash(
      totalSteps,
      currentLevel,
      dailySteps,
      averageSteps,
      lastActive,
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