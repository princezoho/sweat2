import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:sweat_pets/game/pet_sprite.dart';
import 'package:sweat_pets/models/pet_state.dart';
import 'package:sweat_pets/models/pet.dart';
import 'package:sweat_pets/models/pet_collection.dart';

/// The main game class for SweatPets
class SweatPetGame extends FlameGame {
  /// Current pet state
  PetState? _petState;
  
  /// Current pet type
  Pet? _currentPet;
  
  /// Pet sprite component
  PetSprite? _petSprite;
  
  /// Pet background color
  final Color bgColor;
  
  /// Creates a new SweatPet game instance
  SweatPetGame({
    this.bgColor = const Color(0xFFF0F0F0),
    PetState? initialState,
    Pet? initialPet,
  }) {
    _petState = initialState ?? PetState.initial();
    _currentPet = initialPet ?? PetCollection.getPetById('blue_sweatpet');
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Set background color
    add(
      RectangleComponent(
        size: size,
        position: Vector2.zero(),
        paint: Paint()..color = bgColor,
      ),
    );
    
    // Create pet sprite if we have a valid pet
    if (_currentPet != null) {
      _petSprite = PetSprite(
        pet: _currentPet!,
        level: _petState?.currentLevel ?? 0,
        position: size / 2, // Center of the screen
        size: Vector2(200, 200), // Adjust size as needed
      );
      
      add(_petSprite!);
    }
  }
  
  /// Updates the pet state
  void updatePetState(PetState newState) {
    final previousLevel = _petState?.currentLevel ?? 0;
    _petState = newState;
    
    if (_petSprite != null && newState.currentLevel != previousLevel) {
      _petSprite!.updateLevel(newState.currentLevel);
    }
  }
  
  /// Updates the current pet
  void updatePet(Pet newPet) {
    _currentPet = newPet;
    
    if (_petSprite != null) {
      _petSprite!.updatePet(newPet);
    }
  }
  
  /// Gets the current pet state
  PetState? get petState => _petState;
  
  /// Gets the current pet
  Pet? get currentPet => _currentPet;
}

/// Widget to display the SweatPet game
class SweatPetGameWidget extends StatelessWidget {
  /// Current pet state
  final PetState? petState;
  
  /// Current pet type
  final Pet? pet;
  
  /// Background color
  final Color backgroundColor;
  
  /// Game state changed callback
  final void Function(SweatPetGame game)? onGameCreated;
  
  /// Creates a new SweatPet game widget
  const SweatPetGameWidget({
    super.key,
    this.petState,
    this.pet,
    this.backgroundColor = const Color(0xFFF0F0F0),
    this.onGameCreated,
  });
  
  @override
  Widget build(BuildContext context) {
    // Create the game instance
    final game = SweatPetGame(
      initialState: petState,
      initialPet: pet,
      bgColor: backgroundColor,
    );
    
    // Call the onGameCreated callback if provided
    if (onGameCreated != null) {
      onGameCreated!(game);
    }
    
    // Return the game widget
    return GameWidget(
      game: game,
      backgroundBuilder: (context) => Container(
        color: backgroundColor,
      ),
    );
  }
} 