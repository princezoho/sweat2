import 'package:sweat_pets/game/sweat_pet_game.dart';
import 'package:sweat_pets/models/pet_state.dart';

/// A class to hold a reference to the game instance
class GameReference {
  /// The game instance
  SweatPetGame game;
  
  /// Creates a new GameReference
  GameReference(this.game);
  
  /// Gets the current pet state
  PetState? get currentPet => game.petState;
  
  /// Updates the pet state
  void updatePetState(PetState newState) {
    game.updatePetState(newState);
  }
  
  /// Get current step count
  int get steps => currentPet?.totalSteps ?? 0;
} 