import 'package:flutter_test/flutter_test.dart';
import 'package:sweat_pets/models/pet_state.dart';

void main() {
  group('PetState', () {
    test('initial state is created with correct default values', () {
      final state = PetState.initial();
      
      expect(state.totalSteps, 0);
      expect(state.currentLevel, 0);
      expect(state.achievements, isEmpty);
      expect(state.lastActive.difference(DateTime.now()).inSeconds.abs() < 2, true);
    });

    test('fromJson creates correct PetState instance', () {
      final now = DateTime.now();
      final json = {
        'totalSteps': 1000,
        'currentLevel': 2,
        'lastActive': now.toIso8601String(),
        'achievements': ['First Steps', 'Level Up'],
      };

      final state = PetState.fromJson(json);

      expect(state.totalSteps, 1000);
      expect(state.currentLevel, 2);
      expect(state.lastActive.isAtSameMomentAs(now), true);
      expect(state.achievements, ['First Steps', 'Level Up']);
    });

    test('toJson creates correct JSON representation', () {
      final now = DateTime.now();
      final state = PetState(
        totalSteps: 1000,
        currentLevel: 2,
        lastActive: now,
        achievements: ['First Steps', 'Level Up'],
      );

      final json = state.toJson();

      expect(json['totalSteps'], 1000);
      expect(json['currentLevel'], 2);
      expect(json['lastActive'], now.toIso8601String());
      expect(json['achievements'], ['First Steps', 'Level Up']);
    });

    test('copyWith creates new instance with updated values', () {
      final original = PetState.initial();
      final updated = original.copyWith(
        totalSteps: 500,
        currentLevel: 1,
      );

      expect(updated.totalSteps, 500);
      expect(updated.currentLevel, 1);
      expect(updated.lastActive, original.lastActive);
      expect(updated.achievements, original.achievements);
    });

    test('equality works correctly', () {
      final now = DateTime.now();
      final state1 = PetState(
        totalSteps: 1000,
        currentLevel: 2,
        lastActive: now,
        achievements: ['First Steps'],
      );

      final state2 = PetState(
        totalSteps: 1000,
        currentLevel: 2,
        lastActive: now,
        achievements: ['First Steps'],
      );

      final state3 = PetState(
        totalSteps: 2000,
        currentLevel: 2,
        lastActive: now,
        achievements: ['First Steps'],
      );

      expect(state1 == state2, true);
      expect(state1 == state3, false);
    });

    test('toString provides readable representation', () {
      final now = DateTime.now();
      final state = PetState(
        totalSteps: 1000,
        currentLevel: 2,
        lastActive: now,
        achievements: ['First Steps'],
      );

      final string = state.toString();
      expect(string.contains('totalSteps: 1000'), true);
      expect(string.contains('currentLevel: 2'), true);
      expect(string.contains('achievements: [First Steps]'), true);
    });
  });
} 