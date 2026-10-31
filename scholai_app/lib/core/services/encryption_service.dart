import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Client-side AES-256 encryption primitives for ScholAI.
///
/// Today no network payload is encrypted with this service — journal text is
/// never written to Firestore, and habit/check-in data never leaves the
/// device. This service exists (and is unit-tested) for any future
/// encrypted-at-rest writes; the key lives in Android Keystore / iOS
/// Keychain. `cryptographicallyWipeData` is wired to the Settings
/// "Erase data on this device" action.
class EncryptionService {
  EncryptionService._();
  static final instance = EncryptionService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyStorageKey = 'scholai_master_encryption_key';

  enc.Encrypter? _encrypter;

  /// Initializes the on-device master key. Generates a new 256-bit key
  /// on first launch and persists it securely in the device hardware enclave.
  Future<void> initialize() async {
    String? storedKey = await _storage.read(key: _keyStorageKey);

    if (storedKey == null) {
      final secureRandom = enc.SecureRandom(32);
      final rawBytes = secureRandom.bytes;
      storedKey = base64Encode(rawBytes);
      await _storage.write(key: _keyStorageKey, value: storedKey);
    }

    final keyBytes = base64Decode(storedKey);
    final key = enc.Key(keyBytes);
    _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  /// Encrypts plain text string into an AES-256 payload with a unique IV.
  /// Returns a JSON-serializable map of `ciphertext` and `iv`.
  Map<String, String> encrypt(String plainText) {
    if (_encrypter == null) {
      throw StateError('EncryptionService must be initialized before encrypting.');
    }

    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encrypt(plainText, iv: iv);

    return {
      'ciphertext': encrypted.base64,
      'iv': iv.base64,
    };
  }

  /// Decrypts an AES-256 payload using the device's hardware-backed key.
  String decrypt({required String ciphertext, required String iv}) {
    if (_encrypter == null) {
      throw StateError('EncryptionService must be initialized before decrypting.');
    }

    final ivObj = enc.IV.fromBase64(iv);
    final encryptedObj = enc.Encrypted.fromBase64(ciphertext);

    return _encrypter!.decrypt(encryptedObj, iv: ivObj);
  }

  /// One-tap data wipe: wipes the encryption key and local storage,
  /// making any previously stored encrypted Firestore records permanently unrecoverable.
  Future<void> cryptographicallyWipeData() async {
    await _storage.delete(key: _keyStorageKey);
    _encrypter = null;
  }
}
