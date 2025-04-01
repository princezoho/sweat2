import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweat_pets/models/pet.dart';
import 'package:sweat_pets/models/pet_state.dart';
import 'package:sweat_pets/models/pet_collection.dart';

/// Represents a user's profile in the game
class UserProfile {
  /// Unique identifier
  final String id;
  
  /// User's display name
  String name;
  
  /// Total steps across all pets
  int steps;
  
  /// Current active pet ID
  String activePetId;
  
  /// Map of pet IDs to their states
  final Map<String, PetState> petStates;
  
  /// List of unlocked achievements
  final List<String> achievements;
  
  /// History of step activities
  final List<Map<String, dynamic>> history;
  
  /// Last sync timestamp
  DateTime? lastSync;
  
  /// Creates a new UserProfile instance
  UserProfile({
    required this.id,
    required this.name,
    required this.steps,
    required this.activePetId,
    required this.petStates,
    required this.achievements,
    required this.history,
    this.lastSync,
  });
  
  /// Creates a default UserProfile
  factory UserProfile.defaultProfile() {
    const defaultPetId = 'sweatpet';
    return UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Trainer',
      steps: 0,
      activePetId: defaultPetId,
      petStates: {
        defaultPetId: PetState.initial(),
      },
      achievements: [],
      history: [],
      lastSync: DateTime.now(),
    );
  }
  
  /// Loads the UserProfile from storage
  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_profile');
    
    if (data != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(data);
        return UserProfile.fromJson(json);
      } catch (e) {
        print('Error loading profile: $e');
        return UserProfile.defaultProfile();
      }
    }
    
    return UserProfile.defaultProfile();
  }
  
  /// Saves the UserProfile to storage
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(toJson()));
  }
  
  /// Converts UserProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'steps': steps,
      'activePetId': activePetId,
      'petStates': petStates.map((key, value) => MapEntry(key, value.toJson())),
      'achievements': achievements,
      'history': history,
      'lastSync': lastSync?.toIso8601String(),
    };
  }
  
  /// Creates a UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final Map<String, PetState> states = {};
    final Map<String, dynamic> statesJson = json['petStates'] as Map<String, dynamic>;
    
    statesJson.forEach((key, value) {
      states[key] = PetState.fromJson(value as Map<String, dynamic>);
    });
    
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      steps: json['steps'] as int,
      activePetId: json['activePetId'] as String,
      petStates: states,
      achievements: List<String>.from(json['achievements'] as List),
      history: List<Map<String, dynamic>>.from(json['history'] as List),
      lastSync: json['lastSync'] != null ? DateTime.parse(json['lastSync'] as String) : null,
    );
  }
  
  /// Gets the active pet state
  PetState? get activePetState => petStates[activePetId];
  
  /// Gets the active pet
  Pet? get activePet => PetCollection.getPetById(activePetId);
  
  /// Sets the active pet
  void setActivePet(String petId) {
    if (petStates.containsKey(petId)) {
      activePetId = petId;
    }
  }
  
  /// Adds health steps to the active pet
  Future<void> addHealthSteps(int healthSteps) async {
    if (activePetState == null) return;
    
    final newState = activePetState!.addSteps(healthSteps);
    petStates[activePetId] = newState;
    steps += healthSteps;
    
    // Add to history
    history.add({
      'date': DateTime.now().toIso8601String(),
      'steps': healthSteps,
      'type': 'health',
      'petId': activePetId,
    });
    
    lastSync = DateTime.now();
    await save();
  }
  
  /// Adds manual steps to the active pet
  Future<void> addManualSteps(int stepsToAdd) async {
    if (activePetState == null) return;
    
    final newState = activePetState!.addManualSteps(stepsToAdd);
    petStates[activePetId] = newState;
    steps += stepsToAdd;
    
    // Add to history
    history.add({
      'date': DateTime.now().toIso8601String(),
      'steps': stepsToAdd,
      'type': 'manual',
      'petId': activePetId,
    });
    
    lastSync = DateTime.now();
    await save();
  }
  
  /// Removes steps from the active pet
  Future<void> removeSteps(int stepsToRemove) async {
    if (activePetState == null) return;
    
    final newState = activePetState!.removeSteps(stepsToRemove);
    petStates[activePetId] = newState;
    steps = steps > stepsToRemove ? steps - stepsToRemove : 0;
    
    // Add to history
    history.add({
      'date': DateTime.now().toIso8601String(),
      'steps': -stepsToRemove,
      'type': 'manual_remove',
      'petId': activePetId,
    });
    
    lastSync = DateTime.now();
    await save();
  }
  
  /// Resets daily steps for the active pet
  Future<void> resetDaily() async {
    if (activePetState == null) return;
    
    final newState = activePetState!.resetDailySteps();
    petStates[activePetId] = newState;
    
    // Add to history
    history.add({
      'date': DateTime.now().toIso8601String(),
      'steps': 0,
      'type': 'reset_daily',
      'petId': activePetId,
    });
    
    lastSync = DateTime.now();
    await save();
  }
  
  /// Completely resets the active pet
  Future<void> resetComplete() async {
    if (activePetState == null) return;
    
    petStates[activePetId] = PetState.reset();
    steps = 0;
    
    // Add to history
    history.add({
      'date': DateTime.now().toIso8601String(),
      'steps': 0,
      'type': 'reset_complete',
      'petId': activePetId,
    });
    
    lastSync = DateTime.now();
    await save();
  }
  
  /// Updates the active pet's level
  Future<void> updatePetLevel(int newLevel) async {
    if (activePetState == null) return;
    
    final newState = activePetState!.copyWith(currentLevel: newLevel);
    petStates[activePetId] = newState;
    await save();
  }
  
  /// Gets all unlocked pets
  List<Pet> getUnlockedPets() {
    if (activePetState == null) return [];
    return PetCollection.getUnlockedPets(activePetState!);
  }
  
  /// Gets all locked pets
  List<Pet> getLockedPets() {
    if (activePetState == null) return PetCollection.availablePets;
    return PetCollection.getLockedPets(activePetState!);
  }
  
  /// Unlocks a new pet if requirements are met
  Future<bool> tryUnlockPet(String petId) async {
    if (activePetState == null) return false;
    
    final pet = PetCollection.getPetById(petId);
    if (pet == null) return false;
    
    if (PetCollection.canUnlockPet(pet, activePetState!)) {
      // Create initial state for the new pet
      petStates[petId] = PetState.initial();
      await save();
      return true;
    }
    
    return false;
  }
  
  /// Updates achievements list
  Future<void> setAchievements(List<String> newAchievements) async {
    // Create a new list to avoid modifying the final field directly
    achievements.clear();
    achievements.addAll(newAchievements);
    await save();
  }
} 