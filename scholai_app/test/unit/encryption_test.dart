import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypt/encrypt.dart' as enc;

void main() {
  group('Zero-Knowledge Encryption Tests', () {
    late enc.Encrypter encrypter;
    late enc.Key key;

    setUp(() {
      final randomBytes = enc.SecureRandom(32).bytes;
      key = enc.Key(randomBytes);
      encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    });

    test('successfully encrypts and decrypts sensitive journal entries', () {
      const privateJournalText = 'I am overwhelmed with law school exams and feel completely isolated.';

      final iv = enc.IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(privateJournalText, iv: iv);

      // Ciphertext must never match plaintext
      expect(encrypted.base64, isNot(equals(privateJournalText)));

      // Decryption with the same key and IV must recover exact plaintext
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      expect(decrypted, equals(privateJournalText));
    });

    test('each encryption produces a unique ciphertext and IV for the same input', () {
      const repeatedText = 'Same feeling today.';

      final iv1 = enc.IV.fromSecureRandom(16);
      final encrypted1 = encrypter.encrypt(repeatedText, iv: iv1);

      final iv2 = enc.IV.fromSecureRandom(16);
      final encrypted2 = encrypter.encrypt(repeatedText, iv: iv2);

      // Distinct IVs prevent pattern analysis / frequency attacks
      expect(iv1.base64, isNot(equals(iv2.base64)));
      expect(encrypted1.base64, isNot(equals(encrypted2.base64)));
    });

    test('fails to decrypt if an incorrect key is provided', () {
      const message = 'Confidential reflections';
      final iv = enc.IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(message, iv: iv);

      final wrongKey = enc.Key(enc.SecureRandom(32).bytes);
      final wrongEncrypter = enc.Encrypter(enc.AES(wrongKey, mode: enc.AESMode.cbc));

      expect(() => wrongEncrypter.decrypt(encrypted, iv: iv), throwsA(isA<ArgumentError>()));
    });
  });
}
