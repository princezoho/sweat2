import 'dart:convert';

/// Represents the current state of a pet in the game
class PetState {
  /// Total accumulated steps
  final int totalSteps;
  
  /// Current evolution level of the pet
  final int currentLevel;
  
  /// Timestamp of last user activity
  final DateTime lastActive;
  
  /// List of unlocked achievements
  final List<String> achievements;

  /// Creates a new PetState instance
  PetState({
    required this.totalSteps,
    required this.currentLevel,
    required this.lastActive,
    required this.achievements,
  });

  /// Creates a default PetState with initial values
  factory PetState.initial() {
    return PetState(
      totalSteps: 0,
      currentLevel: 0,
      lastActive: DateTime.now(),
      achievements: [],
    );
  }

  /// Creates a PetState from JSON
  factory PetState.fromJson(Map<String, dynamic> json) {
    return PetState(
      totalSteps: json['totalSteps'] as int,
      currentLevel: json['currentLevel'] as int,
      lastActive: DateTime.parse(json['lastActive'] as String),
      achievements: List<String>.from(json['achievements'] as List),
    );
  }

  /// Converts PetState to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalSteps': totalSteps,
      'currentLevel': currentLevel,
      'lastActive': lastActive.toIso8601String(),
      'achievements': achievements,
    };
  }

  /// Creates a copy of PetState with optional new values
  PetState copyWith({
    int? totalSteps,
    int? currentLevel,
    DateTime? lastActive,
    List<String>? achievements,
  }) {
    return PetState(
      totalSteps: totalSteps ?? this.totalSteps,
      currentLevel: currentLevel ?? this.currentLevel,
      lastActive: lastActive ?? this.lastActive,
      achievements: achievements ?? List<String>.from(this.achievements),
    );
  }

  @override
  String toString() {
    return 'PetState(totalSteps: $totalSteps, currentLevel: $currentLevel, lastActive: $lastActive, achievements: $achievements)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetState &&
        other.totalSteps == totalSteps &&
        other.currentLevel == currentLevel &&
        other.lastActive.isAtSameMomentAs(lastActive) &&
        listEquals(other.achievements, achievements);
  }

  @override
  int get hashCode {
    return Object.hash(
      totalSteps,
      currentLevel,
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