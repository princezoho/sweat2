import 'package:sweat_pets/models/user_profile.dart';
import 'package:sweat_pets/models/achievements.dart';

/// Updates the user profile with the new step count from health app
Future<void> applyNewStepsToProfile(int newSteps) async {
  final profile = await UserProfile.load();
  
  // Add health steps
  await profile.addHealthSteps(newSteps);
  
  // Check for achievements
  await Achievements.checkForNewAchievements(profile);
}

/// Add manually input steps to the profile
Future<void> addManualStepsToProfile(int stepsToAdd) async {
  if (stepsToAdd <= 0) return;
  
  final profile = await UserProfile.load();
  
  // Add manual steps
  await profile.addManualSteps(stepsToAdd);
  
  // Check for achievements
  await Achievements.checkForNewAchievements(profile);
}

/// Remove steps from the profile
Future<void> removeStepsFromProfile(int stepsToRemove) async {
  if (stepsToRemove <= 0) return;
  
  final profile = await UserProfile.load();
  await profile.removeSteps(stepsToRemove);
}

/// Reset daily steps
Future<void> resetDailySteps() async {
  final profile = await UserProfile.load();
  await profile.resetDaily();
}

/// Reset everything
Future<void> resetComplete() async {
  final profile = await UserProfile.load();
  await profile.resetComplete();
}

/// Calculates pet level based on step count
int calculatePetLevel(int steps) {
  if (steps >= 10000) return 5;
  if (steps >= 5000) return 4;
  if (steps >= 2500) return 3;
  if (steps >= 1000) return 2;
  return 1;
}

void updatePetUI(int petLevel) {
  // This will be implemented in the UI layer
  // You can use a state management solution or callback to update the UI
} 