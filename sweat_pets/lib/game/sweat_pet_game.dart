import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sweat_pets/game/pet_sprite.dart';
import 'package:sweat_pets/models/pet_state.dart';

/// The main game class for SweatPets
class SweatPetGame extends FlameGame {
  /// Current pet state
  PetState? _petState;
  
  /// Pet sprite component
  PetSprite? _petSprite;
  
  /// Pet background color
  final Color backgroundColor;
  
  /// Creates a new SweatPet game instance
  SweatPetGame({
    this.backgroundColor = const Color(0xFFF0F0F0),
    PetState? initialState,
  }) {
    _petState = initialState ?? PetState.initial();
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Set background color
    camera.backdrop.add(ColorBackground(backgroundColor));
    
    // Create pet sprite
    _petSprite = PetSprite(
      level: _petState!.currentLevel,
      position: size / 2, // Center of the screen
      size: Vector2(200, 200), // Adjust size as needed
    );
    
    add(_petSprite!);
  }
  
  /// Updates the pet state
  void updatePetState(PetState newState) {
    final previousLevel = _petState?.currentLevel ?? 0;
    _petState = newState;
    
    if (_petSprite != null && newState.currentLevel != previousLevel) {
      _petSprite!.updateLevel(newState.currentLevel);
    }
  }
  
  /// Gets the current pet state
  PetState? get petState => _petState;
}

/// Widget to display the SweatPet game
class SweatPetGameWidget extends StatelessWidget {
  /// Current pet state
  final PetState? petState;
  
  /// Background color
  final Color backgroundColor;
  
  /// Game state changed callback
  final void Function(SweatPetGame game)? onGameCreated;
  
  /// Creates a new SweatPet game widget
  const SweatPetGameWidget({
    super.key,
    this.petState,
    this.backgroundColor = const Color(0xFFF0F0F0),
    this.onGameCreated,
  });
  
  @override
  Widget build(BuildContext context) {
    return GameWidget<SweatPetGame>(
      game: SweatPetGame(
        initialState: petState,
        backgroundColor: backgroundColor,
      ),
      backgroundBuilder: (context) => Container(
        color: backgroundColor,
      ),
      overlayBuilderMap: const {},
      initialActiveOverlays: const [],
      gameFactory: () {
        final game = SweatPetGame(
          initialState: petState,
          backgroundColor: backgroundColor,
        );
        
        if (onGameCreated != null) {
          onGameCreated!(game);
        }
        
        return game;
      },
    );
  }
} 