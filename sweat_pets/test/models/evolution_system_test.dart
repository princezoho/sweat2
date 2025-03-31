import 'package:flutter_test/flutter_test.dart';
import 'package:sweat_pets/models/evolution_system.dart';

void main() {
  group('EvolutionSystem', () {
    test('calculateDailyLevel returns correct levels for different step counts', () {
      // Level 0
      expect(EvolutionSystem.calculateDailyLevel(0), equals(0));
      expect(EvolutionSystem.calculateDailyLevel(999), equals(0));
      
      // Level 1
      expect(EvolutionSystem.calculateDailyLevel(1000), equals(1));
      expect(EvolutionSystem.calculateDailyLevel(2499), equals(1));
      
      // Level 2
      expect(EvolutionSystem.calculateDailyLevel(2500), equals(2));
      expect(EvolutionSystem.calculateDailyLevel(4999), equals(2));
      
      // Level 3
      expect(EvolutionSystem.calculateDailyLevel(5000), equals(3));
      expect(EvolutionSystem.calculateDailyLevel(7999), equals(3));
      
      // Level 4
      expect(EvolutionSystem.calculateDailyLevel(8000), equals(4));
      expect(EvolutionSystem.calculateDailyLevel(9999), equals(4));
      
      // Level 5
      expect(EvolutionSystem.calculateDailyLevel(10000), equals(5));
      expect(EvolutionSystem.calculateDailyLevel(14999), equals(5));
      
      // Level 6
      expect(EvolutionSystem.calculateDailyLevel(15000), equals(6));
      expect(EvolutionSystem.calculateDailyLevel(19999), equals(6));
      
      // Level 7
      expect(EvolutionSystem.calculateDailyLevel(20000), equals(7));
      expect(EvolutionSystem.calculateDailyLevel(100000), equals(7));
    });
    
    test('calculateAverageLevel returns correct levels for different average step counts', () {
      // Level 0
      expect(EvolutionSystem.calculateAverageLevel(0), equals(0));
      expect(EvolutionSystem.calculateAverageLevel(999), equals(0));
      
      // Level 1
      expect(EvolutionSystem.calculateAverageLevel(1000), equals(1));
      expect(EvolutionSystem.calculateAverageLevel(2499), equals(1));
      
      // Level 7
      expect(EvolutionSystem.calculateAverageLevel(20000), equals(7));
      expect(EvolutionSystem.calculateAverageLevel(100000), equals(7));
    });
    
    test('willEvolve returns true when new level is higher', () {
      expect(EvolutionSystem.willEvolve(0, 1), isTrue);
      expect(EvolutionSystem.willEvolve(3, 5), isTrue);
    });
    
    test('willEvolve returns false when new level is same or lower', () {
      expect(EvolutionSystem.willEvolve(1, 1), isFalse);
      expect(EvolutionSystem.willEvolve(5, 3), isFalse);
    });
    
    test('willDevolve returns true when new level is lower', () {
      expect(EvolutionSystem.willDevolve(5, 3), isTrue);
      expect(EvolutionSystem.willDevolve(1, 0), isTrue);
    });
    
    test('willDevolve returns false when new level is same or higher', () {
      expect(EvolutionSystem.willDevolve(1, 1), isFalse);
      expect(EvolutionSystem.willDevolve(3, 5), isFalse);
    });
    
    test('getNextThreshold returns correct threshold for next level', () {
      expect(EvolutionSystem.getNextThreshold(0), equals(1000));
      expect(EvolutionSystem.getNextThreshold(3), equals(8000));
      expect(EvolutionSystem.getNextThreshold(6), equals(20000));
      expect(EvolutionSystem.getNextThreshold(7), equals(20000)); // Max level, returns the highest threshold
    });
    
    test('getProgressToNextLevel returns correct progress percentage', () {
      // No progress at level start
      expect(EvolutionSystem.getProgressToNextLevel(0, 0), equals(0.0));
      
      // Halfway progress
      expect(EvolutionSystem.getProgressToNextLevel(0, 500), closeTo(0.5, 0.01));
      
      // Almost at next level
      expect(EvolutionSystem.getProgressToNextLevel(0, 999), closeTo(0.999, 0.01));
      
      // Just reached the next level (should be calculated for the new level)
      expect(EvolutionSystem.getProgressToNextLevel(1, 1000), equals(0.0));
      
      // Max level always returns 1.0
      expect(EvolutionSystem.getProgressToNextLevel(7, 20000), equals(1.0));
      expect(EvolutionSystem.getProgressToNextLevel(7, 100000), equals(1.0));
    });
  });
} 