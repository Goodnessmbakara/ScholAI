import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholai_app/shared/widgets/scholai_mark.dart';

void main() {
  group('ScholAIMark Brand Vector Component Tests', () {
    testWidgets('renders cleanly without wordmark by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScholAIMark(size: 64),
          ),
        ),
      );

      expect(find.byType(ScholAIMark), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      // Wordmark should not be rendered by default
      expect(find.text('ScholAI'), findsNothing);
    });

    testWidgets('renders brand wordmark when showWordmark is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScholAIMark(
              size: 80,
              showWordmark: true,
            ),
          ),
        ),
      );

      expect(find.byType(ScholAIMark), findsOneWidget);
      expect(find.text('ScholAI'), findsOneWidget);
    });
  });
}
