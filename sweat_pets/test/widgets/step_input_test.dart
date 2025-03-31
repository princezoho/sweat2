import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweat_pets/widgets/step_input.dart';

void main() {
  group('StepInput', () {
    testWidgets('displays current steps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepInput(
              currentSteps: 1000,
              onStepsAdded: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Daily Steps: 1000'), findsOneWidget);
    });

    testWidgets('validates input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepInput(
              currentSteps: 0,
              onStepsAdded: (_) {},
            ),
          ),
        ),
      );

      // Empty input
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Please enter a number'), findsOneWidget);

      // Invalid input
      await tester.enterText(find.byType(TextFormField), '0');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Please enter a positive number'), findsOneWidget);
    });

    testWidgets('calls onStepsAdded with valid input', (tester) async {
      int? addedSteps;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepInput(
              currentSteps: 0,
              onStepsAdded: (steps) => addedSteps = steps,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '100');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(addedSteps, 100);
      expect(find.text('100'), findsNothing); // Input should be cleared
    });
  });
} 