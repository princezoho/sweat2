import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:sweat_pets/models/evolution_system.dart';

/// Represents the visual pet sprite in the game
class PetSprite extends SpriteComponent with HasGameRef {
  /// Current evolution level
  int _level = 0;
  
  /// Cached sprites for each evolution level
  final Map<int, Sprite> _sprites = {};
  
  /// Creates a new pet sprite
  PetSprite({
    required int level,
    Vector2? position,
    Vector2? size,
  }) : super(position: position, size: size) {
    _level = level;
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load all pet sprites for each evolution level
    for (int i = 0; i <= EvolutionSystem.maxLevel; i++) {
      final sprite = await Sprite.load('sweatpet$i.png');
      _sprites[i] = sprite;
    }
    
    // Set the initial sprite based on level
    sprite = _sprites[_level];
    
    // Center anchor point for better positioning
    anchor = Anchor.center;
  }
  
  /// Updates the pet to show the specified evolution level
  void updateLevel(int level) {
    if (_level == level) return;
    
    // Clamp level to valid range
    final newLevel = level.clamp(0, EvolutionSystem.maxLevel);
    
    if (_sprites.containsKey(newLevel)) {
      _level = newLevel;
      sprite = _sprites[newLevel];
    }
  }
  
  /// Get the current evolution level
  int get level => _level;
} 