import 'package:flutter/material.dart';

/// Represents a pet type in the game
class Pet {
  /// Unique identifier for the pet type
  final String id;
  
  /// Display name of the pet
  final String name;
  
  /// Description of the pet
  final String description;
  
  /// Base color theme for the pet
  final Color baseColor;
  
  /// Whether this pet is unlocked
  final bool isUnlocked;
  
  /// Requirements to unlock this pet
  final Map<String, dynamic> unlockRequirements;
  
  /// Evolution colors for each level
  final List<Color> evolutionColors;
  
  /// Creates a new Pet instance
  const Pet({
    required this.id,
    required this.name,
    required this.description,
    required this.baseColor,
    this.isUnlocked = false,
    required this.unlockRequirements,
    required this.evolutionColors,
  });
  
  /// Creates a copy of this pet with optional new values
  Pet copyWith({
    String? id,
    String? name,
    String? description,
    Color? baseColor,
    bool? isUnlocked,
    Map<String, dynamic>? unlockRequirements,
    List<Color>? evolutionColors,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      baseColor: baseColor ?? this.baseColor,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockRequirements: unlockRequirements ?? Map<String, dynamic>.from(this.unlockRequirements),
      evolutionColors: evolutionColors ?? List<Color>.from(this.evolutionColors),
    );
  }
  
  /// Converts pet to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'baseColor': baseColor.value,
      'isUnlocked': isUnlocked,
      'unlockRequirements': unlockRequirements,
      'evolutionColors': evolutionColors.map((c) => c.value).toList(),
    };
  }
  
  /// Creates a Pet from JSON
  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      baseColor: Color(json['baseColor'] as int),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockRequirements: Map<String, dynamic>.from(json['unlockRequirements'] as Map),
      evolutionColors: (json['evolutionColors'] as List)
          .map((c) => Color(c as int))
          .toList(),
    );
  }
} 