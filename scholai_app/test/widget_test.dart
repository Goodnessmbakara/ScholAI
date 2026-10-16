import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholai_app/shared/widgets/scholai_mark.dart';

void main() {
  testWidgets('ScholAI mark renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ScholAIMark(size: 48)),
      ),
    );
    expect(find.byType(ScholAIMark), findsOneWidget);
  });
}
