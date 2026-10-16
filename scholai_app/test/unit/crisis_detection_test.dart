import 'package:flutter_test/flutter_test.dart';
import 'package:scholai_app/core/utils/crisis_detection.dart';

void main() {
  group('Crisis Detection & Safety Filter Tests', () {
    test('should detect explicit English crisis signals', () {
      expect(CrisisDetection.containsCrisisSignal('I feel like I want to end my life'), isTrue);
      expect(CrisisDetection.containsCrisisSignal('I just want to die honestly'), isTrue);
      expect(CrisisDetection.containsCrisisSignal('There is no point living anymore'), isTrue);
      expect(CrisisDetection.containsCrisisSignal('Thinking about suicide today'), isTrue);
    });

    test('should detect localized Nigerian phrases of deep despair', () {
      expect(CrisisDetection.containsCrisisSignal('Abeg, i don tire for this life'), isTrue);
      expect(CrisisDetection.containsCrisisSignal('Honestly nothing dey for me again'), isTrue);
      expect(CrisisDetection.containsCrisisSignal('Wetin i dey find for this world sef'), isTrue);
    });

    test('should NOT flag normal academic stress or benign expressions', () {
      expect(CrisisDetection.containsCrisisSignal('I am very stressed about my 400L exams'), isFalse);
      expect(CrisisDetection.containsCrisisSignal('I am tired after reading all night in the library'), isFalse);
      expect(CrisisDetection.containsCrisisSignal('Life on campus is tough right now with money'), isFalse);
      expect(CrisisDetection.containsCrisisSignal('I need help organizing my study schedule'), isFalse);
      expect(CrisisDetection.containsCrisisSignal('Good morning, how are you today?'), isFalse);
    });
  });
}
