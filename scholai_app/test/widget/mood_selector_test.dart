import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholai_app/features/checkin/presentation/widgets/mood_selector.dart';

void main() {
  group('MoodSelector Component Tests', () {
    testWidgets('renders all 5 mood options with correct labels and emojis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodSelector(
              selectedMood: null,
              onMoodSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Rough'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Okay'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Great'), findsOneWidget);

      expect(find.text('😞'), findsOneWidget);
      expect(find.text('😕'), findsOneWidget);
      expect(find.text('😐'), findsOneWidget);
      expect(find.text('🙂'), findsOneWidget);
      expect(find.text('😊'), findsOneWidget);
    });

    testWidgets('triggers onMoodSelected callback with correct index when tapped', (tester) async {
      int? tappedMood;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodSelector(
              selectedMood: null,
              onMoodSelected: (val) => tappedMood = val,
            ),
          ),
        ),
      );

      // Tap on 'Okay' (3rd mood item, value = 3)
      await tester.tap(find.text('Okay'));
      await tester.pumpAndSettle();

      expect(tappedMood, equals(3));

      // Tap on 'Rough' (1st mood item, value = 1)
      await tester.tap(find.text('Rough'));
      await tester.pumpAndSettle();

      expect(tappedMood, equals(1));
    });
  });
}
