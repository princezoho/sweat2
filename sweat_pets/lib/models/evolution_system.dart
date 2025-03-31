/// Manages pet evolution based on step counts
class EvolutionSystem {
  /// Maximum possible evolution level
  static const int maxLevel = 7;

  /// Thresholds for daily evolution levels (steps required to reach level)
  static const List<int> dailyThresholds = [
    0,      // Level 0: 0-999 steps
    1000,   // Level 1: 1,000-2,499 steps
    2500,   // Level 2: 2,500-4,999 steps
    5000,   // Level 3: 5,000-7,999 steps
    8000,   // Level 4: 8,000-9,999 steps
    10000,  // Level 5: 10,000-14,999 steps
    15000,  // Level 6: 15,000-19,999 steps
    20000,  // Level 7: 20,000+ steps
  ];

  /// Thresholds for average evolution levels (same as daily for this implementation)
  static const List<int> averageThresholds = dailyThresholds;

  /// Calculate daily evolution level based on steps
  static int calculateDailyLevel(int steps) {
    for (int i = dailyThresholds.length - 1; i >= 0; i--) {
      if (steps >= dailyThresholds[i]) {
        return i;
      }
    }
    return 0;
  }

  /// Calculate average evolution level based on average steps
  static int calculateAverageLevel(double averageSteps) {
    for (int i = averageThresholds.length - 1; i >= 0; i--) {
      if (averageSteps >= averageThresholds[i]) {
        return i;
      }
    }
    return 0;
  }

  /// Check if pet will evolve to a new level
  static bool willEvolve(int currentLevel, int newLevel) {
    return newLevel > currentLevel;
  }

  /// Check if pet will devolve to a lower level
  static bool willDevolve(int currentLevel, int newLevel) {
    return newLevel < currentLevel;
  }

  /// Gets the next level threshold for the current level
  static int getNextThreshold(int currentLevel) {
    if (currentLevel >= maxLevel) {
      return dailyThresholds[maxLevel];
    }
    return dailyThresholds[currentLevel + 1];
  }
  
  /// Gets progress to next level as a percentage (0.0 to 1.0)
  static double getProgressToNextLevel(int currentLevel, int steps) {
    if (currentLevel >= maxLevel) {
      return 1.0;
    }
    
    final currentThreshold = dailyThresholds[currentLevel];
    final nextThreshold = dailyThresholds[currentLevel + 1];
    final stepsInThisLevel = steps - currentThreshold;
    final stepsForNextLevel = nextThreshold - currentThreshold;
    
    return stepsInThisLevel / stepsForNextLevel;
  }
} 