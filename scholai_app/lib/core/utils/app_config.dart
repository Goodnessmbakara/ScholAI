import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration. Prefer `--dart-define` over `.env` when both are set.
class AppConfig {
  AppConfig._();

  static const _dartDefineGeminiKey = String.fromEnvironment('GEMINI_API_KEY');

  static String get geminiApiKey {
    if (_dartDefineGeminiKey.isNotEmpty) return _dartDefineGeminiKey;
    if (!dotenv.isInitialized) return '';
    return dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
  }

  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;

  static const _dartDefineNotifyUrl =
      String.fromEnvironment('NOTIFY_WORKER_URL');

  /// Cloudflare Worker that sends FCM pushes. Empty = push disabled.
  static String get notifyWorkerUrl {
    if (_dartDefineNotifyUrl.isNotEmpty) return _dartDefineNotifyUrl;
    if (!dotenv.isInitialized) return '';
    return dotenv.env['NOTIFY_WORKER_URL']?.trim() ?? '';
  }
}
