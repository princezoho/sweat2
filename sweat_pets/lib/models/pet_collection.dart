import 'package:flutter/material.dart';
import 'package:sweat_pets/models/pet.dart';
import 'package:sweat_pets/models/pet_state.dart';

/// Collection of available pets in the game
class PetCollection {
  /// List of all available pets
  static final List<Pet> availablePets = [
    // SweatPet (Classic Blue Character)
    Pet(
      id: 'sweatpet',
      name: 'SweatPet',
      description: 'Your original training buddy that evolves with your steps!',
      baseColor: const Color(0xFF72D4FF),
      isUnlocked: true, // Default pet is always unlocked
      unlockRequirements: const {},
      evolutionColors: const [
        Color(0xFF9EDBFF), // Level 0 - Light Blue
        Color(0xFF72D4FF), // Level 1 - Blue
        Color(0xFF42C8FF), // Level 2 - Brighter Blue
        Color(0xFF18BCFF), // Level 3 - Vibrant Blue
        Color(0xFF00A3E8), // Level 4 - Deep Blue
        Color(0xFF0088C2), // Level 5 - Navy Blue
        Color(0xFF006E9C), // Level 6 - Dark Blue
        Color(0xFF005980), // Level 7 - Dark Navy Blue
      ],
    ),
    
    // MachoPet (Cowboy Hat Character)
    Pet(
      id: 'machopet',
      name: 'Macho Pet',
      description: 'OHHH YEAH! This legendary fitness warrior pumps you up with intense motivation!',
      baseColor: const Color(0xFF1E88E5),
      isUnlocked: true, // ALWAYS UNLOCKED - no restrictions
      unlockRequirements: const {
        'totalSteps': 0, // No steps required
      },
      evolutionColors: const [
        Color(0xFF90CAF9), // Level 0 - Lightest Blue
        Color(0xFF64B5F6), // Level 1 - Light Blue
        Color(0xFF42A5F5), // Level 2 - Blue
        Color(0xFF2196F3), // Level 3 - Medium Blue
        Color(0xFF1E88E5), // Level 4 - Deeper Blue
        Color(0xFF1976D2), // Level 5 - Dark Blue
        Color(0xFF1565C0), // Level 6 - Darker Blue
        Color(0xFF0D47A1), // Level 7 - Darkest Blue
      ],
    ),
  ];
  
  /// Check if a pet can be unlocked based on the current state
  static bool canUnlockPet(Pet pet, PetState state) {
    if (pet.isUnlocked) return true;
    
    // Check total steps requirement
    if (pet.unlockRequirements.containsKey('totalSteps')) {
      final requiredSteps = pet.unlockRequirements['totalSteps'] as int;
      if (state.totalSteps < requiredSteps) return false;
    }
    
    return true;
  }
  
  /// Get a pet by its ID
  static Pet? getPetById(String id) {
    try {
      return availablePets.firstWhere((pet) => pet.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all unlocked pets for a given state
  static List<Pet> getUnlockedPets(PetState state) {
    return availablePets
        .where((pet) => pet.isUnlocked || canUnlockPet(pet, state))
        .toList();
  }
  
  /// Get all locked pets for a given state
  static List<Pet> getLockedPets(PetState state) {
    return availablePets
        .where((pet) => !pet.isUnlocked && !canUnlockPet(pet, state))
        .toList();
  }
} 