import 'package:flutter_test/flutter_test.dart';
import 'package:sweat_pets/models/pet_state.dart';
import 'package:sweat_pets/models/evolution_system.dart';

void main() {
  group('PetState', () {
    test('initial state is created with correct default values', () {
      final state = PetState.initial();
      
      expect(state.totalSteps, 0);
      expect(state.currentLevel, 0);
      expect(state.dailySteps, 0);
      expect(state.averageSteps, 0);
      expect(state.achievements, isEmpty);
      expect(state.lastActive.difference(DateTime.now()).inSeconds.abs() < 2, true);
    });

    test('fromJson creates correct PetState instance', () {
      final now = DateTime.now();
      final json = {
        'totalSteps': 1000,
        'currentLevel': 2,
        'dailySteps': 1000,
        'averageSteps': 500.0,
        'lastReset': now.toIso8601String(),
        'achievements': ['First Steps', 'Level Up'],
      };

      final state = PetState.fromJson(json);

      expect(state.totalSteps, 1000);
      expect(state.currentLevel, 2);
      expect(state.dailySteps, 1000);
      expect(state.averageSteps, 500.0);
      expect(state.lastActive.isAtSameMomentAs(now), true);
      expect(state.achievements, ['First Steps', 'Level Up']);
    });

    test('toJson creates correct JSON representation', () {
      final now = DateTime.now();
      final state = PetState(
        totalSteps: 1000,
        currentLevel: 2,
        dailySteps: 1000,
        averageSteps: 500.0,
        lastActive: now,
        achievements: ['First Steps', 'Level Up'],
      );

      final json = state.toJson();

      expect(json['totalSteps'], 1000);
      expect(json['currentLevel'], 2);
      expect(json['dailySteps'], 1000);
      expect(json['averageSteps'], 500.0);
      expect(json['lastReset'], now.toIso8601String());
      expect(json['achievements'], ['First Steps', 'Level Up']);
    });

    test('copyWith creates new instance with updated values', () {
      final original = PetState.initial();
      final updated = original.copyWith(
        totalSteps: 500,
        currentLevel: 1,
        dailySteps: 500,
        averageSteps: 250.0,
      );

      expect(updated.totalSteps, 500);
      expect(updated.currentLevel, 1);
      expect(updated.dailySteps, 500);
      expect(updated.averageSteps, 250.0);
      expect(updated.lastActive, original.lastActive);
      expect(updated.achievements, original.achievements);
    });

    test('adding steps increases daily and total steps', () {
      final state = PetState.initial();
      final updated = state.addSteps(1000);
      
      expect(updated.totalSteps, 1000);
      expect(updated.dailySteps, 1000);
      expect(updated.currentLevel, 1); // Should evolve to level 1
    });
    
    test('adding steps on a new day resets daily steps', () {
      // Create a state with yesterday's date
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final state = PetState(
        totalSteps: 1000,
        currentLevel: 1,
        dailySteps: 1000,
        averageSteps: 1000.0,
        lastActive: yesterday,
        achievements: [],
      );
      
      final updated = state.addSteps(500);
      
      expect(updated.totalSteps, 1500); // Cumulative
      expect(updated.dailySteps, 500); // Reset for new day
      // Average will be different but should still keep level 1
      expect(updated.currentLevel, EvolutionSystem.calculateAverageLevel(updated.averageSteps));
    });
    
    test('willEvolveWith correctly predicts evolution', () {
      final state = PetState.initial();
      
      // Adding 1000 steps will evolve to level 1
      expect(state.willEvolveWith(1000), isTrue);
      
      // Adding 500 steps won't cause evolution
      expect(state.willEvolveWith(500), isFalse);
    });
    
    test('hasEvolved detects evolution between states', () {
      final state = PetState.initial();
      final evolved = state.addSteps(1000);
      
      expect(evolved.hasEvolved(state), isTrue);
    });
    
    test('getProgressToNextLevel returns correct progress', () {
      final state = PetState(
        totalSteps: 500,
        currentLevel: 0,
        dailySteps: 500,
        averageSteps: 500.0,
        lastActive: DateTime.now(),
        achievements: [],
      );
      
      // Should be 50% of the way to level 1 (1000 steps)
      expect(state.getProgressToNextLevel(), closeTo(0.5, 0.01));
    });
    
    test('getNextLevelThreshold returns correct threshold', () {
      final state = PetState(
        totalSteps: 500,
        currentLevel: 0,
        dailySteps: 500,
        averageSteps: 500.0,
        lastActive: DateTime.now(),
        achievements: [],
      );
      
      // Level 0 -> Level 1 threshold is 1000
      expect(state.getNextLevelThreshold(), equals(1000));
    });

    test('equality works correctly', () {
      final now = DateTime.now();
      final state1 = PetState(
        totalSteps: 1000,
        currentLevel: 2,
        dailySteps: 1000,
        averageSteps: 500.0,
        lastActive: now,
        achievements: ['First Steps'],
      );

      final state2 = PetState(
        totalSteps: 1000,
        currentLevel: 2,
        dailySteps: 1000,
        averageSteps: 500.0,
        lastActive: now,
        achievements: ['First Steps'],
      );

      final state3 = PetState(
        totalSteps: 2000,
        currentLevel: 2,
        dailySteps: 1000,
        averageSteps: 500.0,
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
        dailySteps: 1000,
        averageSteps: 500.0,
        lastActive: now,
        achievements: ['First Steps'],
      );

      final string = state.toString();
      expect(string.contains('totalSteps: 1000'), true);
      expect(string.contains('currentLevel: 2'), true);
      expect(string.contains('dailySteps: 1000'), true);
      expect(string.contains('averageSteps: 500.0'), true);
      expect(string.contains('achievements: [First Steps]'), true);
    });
  });
} 