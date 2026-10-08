import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Crisis Detection & Safety Filter Tests', () {
    // Exact keyword rule set from GeminiService
    final crisisKeywords = [
      'kill myself', 'end my life', 'want to die', 'suicide', 'suicidal',
      'self harm', 'self-harm', 'hurt myself', 'no point living',
      'don\'t want to be here', 'better off dead', 'overdose',
      // Nigerian English / cultural idioms
      'nothing dey for me', 'i don tire for this life', 'wetin i dey find for this world',
    ];

    bool containsCrisisSignal(String text) {
      final lower = text.toLowerCase();
      return crisisKeywords.any((kw) => lower.contains(kw));
    }

    test('should detect explicit English crisis signals', () {
      expect(containsCrisisSignal('I feel like I want to end my life'), isTrue);
      expect(containsCrisisSignal('I just want to die honestly'), isTrue);
      expect(containsCrisisSignal('There is no point living anymore'), isTrue);
      expect(containsCrisisSignal('Thinking about suicide today'), isTrue);
    });

    test('should detect localized Nigerian phrases of deep despair', () {
      expect(containsCrisisSignal('Abeg, i don tire for this life'), isTrue);
      expect(containsCrisisSignal('Honestly nothing dey for me again'), isTrue);
      expect(containsCrisisSignal('Wetin i dey find for this world sef'), isTrue);
    });

    test('should NOT flag normal academic stress or benign expressions', () {
      expect(containsCrisisSignal('I am very stressed about my 400L exams'), isFalse);
      expect(containsCrisisSignal('I am tired after reading all night in the library'), isFalse);
      expect(containsCrisisSignal('Life on campus is tough right now with money'), isFalse);
      expect(containsCrisisSignal('I need help organizing my study schedule'), isFalse);
      expect(containsCrisisSignal('Good morning, how are you today?'), isFalse);
    });
  });
}
