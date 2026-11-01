import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholai_app/shared/models/chat_message.dart';

/// On-device journal transcript — the "Private" chip means here, not cloud.
/// Rolling cap keeps SharedPreferences and the Gemini context window bounded.
class JournalLocalStore {
  JournalLocalStore._();
  static final instance = JournalLocalStore._();

  static const _key = 'journal_messages_v1';
  static const _maxMessages = 200;

  Future<List<ChatMessage>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic> && item['text'] is String)
            ChatMessage(
              text: item['text'] as String,
              isUser: item['isUser'] == true,
              timestamp: DateTime.tryParse(item['at'] as String? ?? ''),
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final tail = messages.length > _maxMessages
        ? messages.sublist(messages.length - _maxMessages)
        : messages;
    await prefs.setString(
      _key,
      jsonEncode([
        for (final m in tail)
          {
            'text': m.text,
            'isUser': m.isUser,
            if (m.timestamp != null) 'at': m.timestamp!.toIso8601String(),
          },
      ]),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
