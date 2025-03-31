import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweat_pets/models/step_counter.dart';

void main() {
  group('StepCounter', () {
    test('initial state has correct default values', () {
      final counter = StepCounter.initial();
      
      expect(counter.dailySteps, 0);
      expect(counter.averageSteps, 0);
      expect(counter.history, isEmpty);
      expect(counter.lastReset.difference(DateTime.now()).inSeconds.abs() < 2, true);
    });

    test('addSteps correctly updates daily steps', () {
      final counter = StepCounter.initial();
      final updated = counter.addSteps(100);
      
      expect(updated.dailySteps, 100);
      expect(updated.history, isEmpty);
      expect(updated.averageSteps, 100.0);
    });

    test('addSteps accumulates steps within same day', () {
      final counter = StepCounter.initial();
      final step1 = counter.addSteps(100);
      final step2 = step1.addSteps(150);
      
      expect(step2.dailySteps, 250);
      expect(step2.history, isEmpty);
      expect(step2.averageSteps, 250.0);
    });

    test('daily steps reset at midnight', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final counter = StepCounter(
        dailySteps: 1000,
        averageSteps: 1000,
        lastReset: yesterday,
        history: [],
      );
      
      final updated = counter.addSteps(100);
      
      expect(updated.dailySteps, 100);
      expect(updated.history.length, 1);
      expect(updated.history.first.steps, 1000);
      expect(updated.history.first.date, yesterday);
      expect(updated.averageSteps, 550.0); // (1000 + 100) / 2
    });

    test('persistence works correctly', () async {
      SharedPreferences.setMockInitialValues({});
      
      // Save some steps
      final counter = StepCounter.initial();
      final updated = counter.addSteps(100);
      await updated.save();
      
      // Load and verify
      final loaded = await StepCounter.load();
      expect(loaded.dailySteps, 100);
      expect(loaded.averageSteps, 100.0);
      expect(loaded.history, isEmpty);
    });

    test('handles corrupted storage gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'step_counter_data': 'invalid json'
      });
      
      final loaded = await StepCounter.load();
      expect(loaded.dailySteps, 0);
      expect(loaded.averageSteps, 0);
      expect(loaded.history, isEmpty);
    });
  });

  group('DailyStepCount', () {
    test('serialization works correctly', () {
      final now = DateTime.now();
      final count = DailyStepCount(
        date: now,
        steps: 1000,
      );
      
      final json = count.toJson();
      final decoded = DailyStepCount.fromJson(json);
      
      expect(decoded.steps, 1000);
      expect(decoded.date.isAtSameMomentAs(now), true);
    });
  });
} 