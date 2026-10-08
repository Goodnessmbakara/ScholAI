import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug('DEBUG', '🔍'),
  info('INFO', '💡'),
  warning('WARN', '⚠️'),
  error('ERROR', '🚨');

  final String label;
  final String icon;
  const LogLevel(this.label, this.icon);
}

/// Privacy-first, structured logger for ScholAI.
/// 
/// Privacy Guarantees:
/// - Automatically disables verbose/debug logs in release builds (`kReleaseMode`).
/// - Strict rule: Journal text and user emotional content must NEVER be passed to the logger.
class AppLogger {
  AppLogger._();

  static void debug(String message, {String tag = 'ScholAI'}) {
    if (!kReleaseMode) {
      _log(LogLevel.debug, message, tag: tag);
    }
  }

  static void info(String message, {String tag = 'ScholAI'}) {
    _log(LogLevel.info, message, tag: tag);
  }

  static void warning(String message, {String tag = 'ScholAI', Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(
    String message, {
    String tag = 'ScholAI',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final formatted = '$time ${level.icon} [$tag] $message';

    developer.log(
      formatted,
      time: DateTime.now(),
      level: _levelToInt(level),
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static int _levelToInt(LogLevel level) {
    return switch (level) {
      LogLevel.debug => 500,
      LogLevel.info => 800,
      LogLevel.warning => 900,
      LogLevel.error => 1000,
    };
  }
}
