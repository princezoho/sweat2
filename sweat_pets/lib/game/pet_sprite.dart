import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sweat_pets/models/evolution_system.dart';

/// Represents the visual pet sprite in the game
class PetSprite extends PositionComponent with HasGameRef {
  /// Current evolution level
  int _level = 0;
  
  /// Cached sprites for each evolution level
  final Map<int, Sprite> _sprites = {};
  
  /// Fallback component for when sprites fail to load
  RectangleComponent? _fallbackComponent;
  
  /// Whether we're using the fallback rendering
  bool _usingFallback = false;

  /// Colors for different evolution levels
  static const List<Color> _evolutionColors = [
    Color(0xFF9EDBFF), // Level 0 - Light Blue
    Color(0xFF72D4FF), // Level 1 - Blue
    Color(0xFF42C8FF), // Level 2 - Brighter Blue
    Color(0xFF18BCFF), // Level 3 - Vibrant Blue
    Color(0xFF00A3E8), // Level 4 - Deep Blue
    Color(0xFF0088C2), // Level 5 - Navy Blue
    Color(0xFF006E9C), // Level 6 - Dark Blue
    Color(0xFF005980), // Level 7 - Dark Navy Blue
  ];
  
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
    
    bool spritesLoaded = false;
    
    // Try to load the sprites
    try {
      // Load all pet sprites for each evolution level
      for (int i = 0; i <= EvolutionSystem.maxLevel; i++) {
        // Define all possible paths to try
        final List<String> pathsToTry = [
          'sweatpet$i.png',             // Base filename
          'assets/sweatpet$i.png',      // Direct assets path
          'assets/images/sweatpet$i.png', // Images subfolder
          'images/sweatpet$i.png',      // Just images folder
        ];
        
        bool loaded = false;
        for (final path in pathsToTry) {
          try {
            debugPrint('Trying to load: $path');
            final sprite = await Sprite.load(path);
            _sprites[i] = sprite;
            debugPrint('✅ Successfully loaded: $path');
            loaded = true;
            break; // Exit the loop once a path works
          } catch (e) {
            // Just try the next path
          }
        }
        
        if (!loaded) {
          debugPrint('❌ Failed to load sprite for level $i from any path');
        }
      }
      
      // If we loaded at least one sprite, we can use sprites
      if (_sprites.isNotEmpty) {
        spritesLoaded = true;
        debugPrint('Loaded ${_sprites.length} sprites successfully');
        
        // Create sprite component with the appropriate sprite
        if (_sprites.containsKey(_level)) {
          final spriteComponent = SpriteComponent(
            sprite: _sprites[_level],
            size: size,
          );
          add(spriteComponent);
          debugPrint('Added sprite component for level $_level');
        } else if (_sprites.isNotEmpty) {
          // Fallback to first available sprite
          final availableLevel = _sprites.keys.first;
          final spriteComponent = SpriteComponent(
            sprite: _sprites[availableLevel]!,
            size: size,
          );
          add(spriteComponent);
          debugPrint('Added fallback sprite component using level $availableLevel');
        }
      }
    } catch (e) {
      debugPrint('Error during sprite loading process: $e');
    }
    
    // If no sprites were loaded, create a fallback visualization
    if (!spritesLoaded) {
      _usingFallback = true;
      debugPrint('Using fallback visualization');
      _createFallbackVisualization();
    }
    
    // Center anchor point for better positioning
    anchor = Anchor.center;
  }
  
  /// Creates a fallback visualization using colored shapes
  void _createFallbackVisualization() {
    // Remove any existing fallback
    _fallbackComponent?.removeFromParent();
    
    // Get the color for the current level
    final color = _getColorForLevel(_level);
    
    // Create a rectangle with the appropriate color
    _fallbackComponent = RectangleComponent(
      size: size,
      paint: Paint()..color = color,
      position: Vector2.zero(),
    );
    
    // Add rounded corners
    _fallbackComponent!.paint.style = PaintingStyle.fill;
    
    // Add the component
    add(_fallbackComponent!);
    debugPrint('Created fallback visualization with color: $color');
  }
  
  /// Gets the color for a specific evolution level
  Color _getColorForLevel(int level) {
    final clampedLevel = level.clamp(0, _evolutionColors.length - 1);
    return _evolutionColors[clampedLevel];
  }
  
  /// Updates the pet to show the specified evolution level
  void updateLevel(int level) {
    if (_level == level) return;
    
    // Clamp level to valid range
    final newLevel = level.clamp(0, EvolutionSystem.maxLevel);
    _level = newLevel;
    
    if (_usingFallback) {
      // Update the fallback visualization
      _createFallbackVisualization();
    } else if (_sprites.containsKey(newLevel)) {
      // Find existing sprite component and update it
      final spriteChildren = children.whereType<SpriteComponent>();
      if (spriteChildren.isNotEmpty) {
        final spriteComponent = spriteChildren.first;
        spriteComponent.sprite = _sprites[newLevel];
        debugPrint('Updated sprite to level $newLevel');
      }
    }
  }
  
  /// Get the current evolution level
  int get level => _level;
} 