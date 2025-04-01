import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sweat_pets/models/evolution_system.dart';
import 'package:sweat_pets/models/pet.dart';

/// Represents the visual pet sprite in the game
class PetSprite extends PositionComponent with HasGameRef {
  /// Current evolution level
  int _level = 0;
  
  /// Current pet type
  final Pet pet;
  
  /// Cached sprites for each evolution level
  final Map<int, Sprite> _sprites = {};
  
  /// Fallback component for when sprites fail to load
  RectangleComponent? _fallbackComponent;
  
  /// Whether we're using the fallback rendering
  bool _usingFallback = false;
  
  /// Creates a new pet sprite
  PetSprite({
    required this.pet,
    required int level,
    Vector2? position,
    Vector2? size,
  }) : super(position: position, size: size) {
    _level = level;
  }
  
  @override
  Future<void> onLoad() async {
    try {
      // Try to load sprites for each evolution level
      for (int i = 0; i <= EvolutionSystem.maxLevel; i++) {
        try {
          final sprite = await gameRef.loadSprite('pets/${pet.id}_level_$i.png');
          _sprites[i] = sprite;
        } catch (e) {
          debugPrint('Failed to load sprite for ${pet.id} level $i: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading sprites: $e');
    }
    
    // If no sprites loaded, create fallback
    if (_sprites.isEmpty) {
      _usingFallback = true;
      _fallbackComponent = RectangleComponent(
        size: size,
        paint: Paint()..color = _getCurrentColor(),
      );
      add(_fallbackComponent!);
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (!_usingFallback) {
      final sprite = _sprites[_level];
      if (sprite != null) {
        sprite.render(
          canvas,
          size: size,
          overridePaint: Paint()..color = _getCurrentColor(),
        );
      }
    }
  }
  
  /// Gets the current color based on evolution level
  Color _getCurrentColor() {
    if (_level >= pet.evolutionColors.length) {
      return pet.evolutionColors.last;
    }
    return pet.evolutionColors[_level];
  }
  
  /// Updates the pet's evolution level
  void updateLevel(int newLevel) {
    _level = newLevel.clamp(0, EvolutionSystem.maxLevel);
    if (_usingFallback && _fallbackComponent != null) {
      _fallbackComponent!.paint.color = _getCurrentColor();
    }
  }
  
  /// Gets the current level
  int get level => _level;
  
  /// Updates the pet type and reloads sprites
  void updatePet(Pet newPet) {
    // Only update if different pet
    if (newPet.id != pet.id) {
      _sprites.clear();
      onLoad();
    }
  }
} 