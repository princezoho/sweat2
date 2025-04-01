import 'package:sweat_pets/game/sweat_pet_game.dart';
import 'package:sweat_pets/models/pet_state.dart';
import 'package:sweat_pets/models/pet_collection.dart';

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
  
  /// Updates the current pet type and its state
  void updateCurrentPet(String petId, PetState petState) {
    // Get the pet from the collection
    final pet = PetCollection.getPetById(petId);
    if (pet != null) {
      // Update the pet type first
      game.updatePet(pet);
      // Then update its state
      updatePetState(petState);
    }
  }
  
  /// Get current daily step count
  int get dailySteps => currentPet?.dailySteps ?? 0;
  
  /// Get total accumulated step count
  int get totalSteps => currentPet?.totalSteps ?? 0;
  
  /// Get 7-day average step count
  double get averageSteps => currentPet?.averageSteps ?? 0;
  
  /// Get daily pet level
  int get dailyLevel => currentPet?.currentLevel ?? 0;
  
  /// Get average pet level
  int get averageLevel => currentPet?.averageLevel ?? 0;
  
  /// Add steps to the pet
  void addSteps(int steps) {
    if (currentPet == null) return;
    final newState = currentPet!.addSteps(steps);
    updatePetState(newState);
  }
  
  /// Remove steps from the pet
  void removeSteps(int steps) {
    if (currentPet == null) return;
    final newState = currentPet!.removeSteps(steps);
    updatePetState(newState);
  }
  
  /// Reset daily steps
  void resetDailySteps() {
    if (currentPet == null) return;
    final newState = currentPet!.resetDailySteps();
    updatePetState(newState);
  }
  
  /// Reset pet completely
  void resetPet() {
    final newState = PetState.reset();
    updatePetState(newState);
  }
  
  /// Add steps manually (adds 1/7th to weekly average)
  void addManualSteps(int steps) {
    if (currentPet == null) return;
    final newState = currentPet!.addManualSteps(steps);
    updatePetState(newState);
  }
} 