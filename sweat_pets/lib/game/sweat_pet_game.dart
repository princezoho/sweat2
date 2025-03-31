import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:sweat_pets/game/pet_sprite.dart';
import 'package:sweat_pets/models/pet_state.dart';

/// The main game class for SweatPets
class SweatPetGame extends FlameGame {
  /// Current pet state
  PetState? _petState;
  
  /// Pet sprite component
  PetSprite? _petSprite;
  
  /// Pet background color - renamed to avoid conflict with inherited method
  final Color bgColor;
  
  /// Creates a new SweatPet game instance
  SweatPetGame({
    this.bgColor = const Color(0xFFF0F0F0),
    PetState? initialState,
  }) {
    _petState = initialState ?? PetState.initial();
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Set background color using a RectangleComponent instead of ColorBackground
    add(
      RectangleComponent(
        size: size,
        position: Vector2.zero(),
        paint: Paint()..color = bgColor,
      ),
    );
    
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
    // Create the game instance
    final game = SweatPetGame(
      initialState: petState,
      bgColor: backgroundColor, // Using our renamed property
    );
    
    // Call the onGameCreated callback if provided
    if (onGameCreated != null) {
      onGameCreated!(game);
    }
    
    // Return the game widget with correct parameters
    return GameWidget(
      game: game,
      backgroundBuilder: (context) => Container(
        color: backgroundColor,
      ),
    );
  }
} 