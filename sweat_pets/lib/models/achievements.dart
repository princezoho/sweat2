import 'package:flutter/material.dart';
import 'package:sweat_pets/models/user_profile.dart';

/// Achievement data structure
class Achievement {
  /// Unique identifier for the achievement
  final String id;
  
  /// Display name of the achievement
  final String title;
  
  /// Description of how to unlock the achievement
  final String description;
  
  /// Icon to display with the achievement
  final IconData icon;
  
  /// Whether this achievement has been unlocked
  final bool unlocked;
  
  /// When the achievement was unlocked (null if not yet unlocked)
  final DateTime? unlockedAt;
  
  /// Creates a new achievement
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
  });
  
  /// Creates an unlocked copy of this achievement
  Achievement unlock() {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      unlocked: true,
      unlockedAt: DateTime.now(),
    );
  }
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unlocked': unlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
  
  /// Create from JSON storage format
  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) {
    return Achievement(
      id: template.id,
      title: template.title,
      description: template.description,
      icon: template.icon,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt'] as String) : null,
    );
  }
}

/// Available achievements in the app
class Achievements {
  /// All available achievements
  static final List<Achievement> all = [
    const Achievement(
      id: 'first_steps',
      title: 'First Steps',
      description: 'Record your first steps with Health integration',
      icon: Icons.directions_walk,
    ),
    const Achievement(
      id: 'level_2',
      title: 'Level Up!',
      description: 'Reach pet level 2',
      icon: Icons.upgrade,
    ),
    const Achievement(
      id: 'level_3',
      title: 'Growing Fast',
      description: 'Reach pet level 3',
      icon: Icons.trending_up,
    ),
    const Achievement(
      id: 'level_4',
      title: 'Maximum Level',
      description: 'Reach pet level 4',
      icon: Icons.star,
    ),
    const Achievement(
      id: 'five_k_steps',
      title: '5K Steps',
      description: 'Walk 5,000 steps in a day',
      icon: Icons.local_fire_department,
    ),
    const Achievement(
      id: 'ten_k_steps',
      title: '10K Steps',
      description: 'Walk 10,000 steps in a day',
      icon: Icons.local_fire_department,
    ),
    const Achievement(
      id: 'stairs_master',
      title: 'Stairs Master',
      description: 'Climb 10 flights of stairs in a day',
      icon: Icons.stairs,
    ),
    const Achievement(
      id: 'three_day_streak',
      title: '3-Day Streak',
      description: 'Record steps for 3 days in a row',
      icon: Icons.calendar_today,
    ),
    const Achievement(
      id: 'week_streak',
      title: 'Week Streak',
      description: 'Record steps for 7 days in a row',
      icon: Icons.date_range,
    ),
  ];
  
  /// Get achievement by ID
  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Check user profile for new achievements and return any newly unlocked ones
  static Future<List<Achievement>> checkForNewAchievements(UserProfile profile) async {
    List<Achievement> newlyUnlocked = [];
    
    // Get current unlocked achievements
    final unlockedIds = profile.achievements;
    
    // Check for each achievement condition
    if (!unlockedIds.contains('first_steps') && profile.steps > 0) {
      final achievement = getById('first_steps')!.unlock();
      newlyUnlocked.add(achievement);
      unlockedIds.add(achievement.id);
    }
    
    if (!unlockedIds.contains('level_2') && ((profile.activePetState?.currentLevel ?? 0) >= 2)) {
      final achievement = getById('level_2')!.unlock();
      newlyUnlocked.add(achievement);
      unlockedIds.add(achievement.id);
    }
    
    if (!unlockedIds.contains('level_3') && ((profile.activePetState?.currentLevel ?? 0) >= 3)) {
      final achievement = getById('level_3')!.unlock();
      newlyUnlocked.add(achievement);
      unlockedIds.add(achievement.id);
    }
    
    if (!unlockedIds.contains('level_4') && ((profile.activePetState?.currentLevel ?? 0) >= 4)) {
      final achievement = getById('level_4')!.unlock();
      newlyUnlocked.add(achievement);
      unlockedIds.add(achievement.id);
    }
    
    if (!unlockedIds.contains('five_k_steps') && profile.steps >= 5000) {
      final achievement = getById('five_k_steps')!.unlock();
      newlyUnlocked.add(achievement);
      unlockedIds.add(achievement.id);
    }
    
    if (!unlockedIds.contains('ten_k_steps') && profile.steps >= 10000) {
      final achievement = getById('ten_k_steps')!.unlock();
      newlyUnlocked.add(achievement);
      unlockedIds.add(achievement.id);
    }
    
    // Check for streak achievements based on history
    if (!unlockedIds.contains('three_day_streak') && hasStreak(profile.history, 3)) {
      final achievement = getById('three_day_streak')!.unlock();
      newlyUnlocked.add(achievement);
      unlockedIds.add(achievement.id);
    }
    
    if (!unlockedIds.contains('week_streak') && hasStreak(profile.history, 7)) {
      final achievement = getById('week_streak')!.unlock();
      newlyUnlocked.add(achievement);
      unlockedIds.add(achievement.id);
    }
    
    // If we unlocked anything new, update the profile
    if (newlyUnlocked.isNotEmpty) {
      // Update the profile's achievements
      await profile.setAchievements(unlockedIds);
    }
    
    return newlyUnlocked;
  }
  
  /// Check if the user has a streak of consecutive days with steps
  static bool hasStreak(List<Map<String, dynamic>> history, int days) {
    if (history.length < days) return false;
    
    // Sort history by date (newest first)
    final sortedHistory = List<Map<String, dynamic>>.from(history)
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    
    // Get today's date
    final today = DateTime.now();
    
    // Check for consecutive days
    DateTime? previousDate;
    int consecutiveDays = 0;
    
    for (var entry in sortedHistory) {
      final dateStr = entry['date'] as String;
      final date = DateTime.parse(dateStr);
      final steps = entry['steps'] as int;
      
      // Skip if no steps recorded
      if (steps <= 0) continue;
      
      if (previousDate == null) {
        // First entry
        previousDate = date;
        consecutiveDays = 1;
      } else {
        // Check if this is the previous day
        final difference = previousDate.difference(date).inDays;
        
        if (difference == 1) {
          // Consecutive day
          consecutiveDays++;
          previousDate = date;
          
          // Return true if we have enough days
          if (consecutiveDays >= days) {
            return true;
          }
        } else if (difference > 1) {
          // Streak broken
          return false;
        }
        // If difference is 0, it's the same day, so we skip
      }
    }
    
    return consecutiveDays >= days;
  }
  
  /// Get all achievements with unlock status
  static List<Achievement> getUserAchievements(UserProfile profile) {
    return all.map((achievement) {
      if (profile.achievements.contains(achievement.id)) {
        // Get unlock date if available
        DateTime? unlockedAt;
        try {
          // In a real implementation, we would store the actual unlock dates
          unlockedAt = DateTime.now().subtract(const Duration(days: 1));
        } catch (e) {
          unlockedAt = null;
        }
        
        return Achievement(
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          icon: achievement.icon,
          unlocked: true,
          unlockedAt: unlockedAt,
        );
      }
      return achievement;
    }).toList();
  }
} 