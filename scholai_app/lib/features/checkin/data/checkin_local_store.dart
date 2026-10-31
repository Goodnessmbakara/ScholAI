import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Today's check-in, kept on the device so leaving the tab does not clear it.
class CheckInDraft {
  final int mood;
  final String? category;

  const CheckInDraft({required this.mood, this.category});
}

/// One saved check-in, keyed by the day it was logged.
class CheckInEntry {
  final DateTime day;
  final int mood;
  final String? category;

  const CheckInEntry({required this.day, required this.mood, this.category});

  static DateTime dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Map<String, dynamic> toJson() => {
        'day': dayOnly(day).toIso8601String(),
        'mood': mood,
        if (category != null) 'category': category,
      };

  static CheckInEntry? tryParse(Map<String, dynamic> json) {
    final mood = json['mood'];
    if (mood is! int || mood < 1 || mood > 5) return null;
    final day = DateTime.tryParse(json['day'] as String? ?? '');
    if (day == null) return null;
    final category = json['category'] as String?;
    return CheckInEntry(
      day: dayOnly(day),
      mood: mood,
      category: category == null || category.isEmpty ? null : category,
    );
  }
}

class CheckInLocalStore {
  CheckInLocalStore._();
  static final instance = CheckInLocalStore._();

  static const _dayKey = 'checkin_day';
  static const _moodKey = 'checkin_mood';
  static const _categoryKey = 'checkin_category';
  static const _historyKey = 'checkin_history_v1';

  Future<CheckInDraft?> loadToday() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_dayKey) != _dayKeyFor(DateTime.now())) return null;
    final mood = prefs.getInt(_moodKey);
    if (mood == null || mood < 1 || mood > 5) return null;
    final category = prefs.getString(_categoryKey);
    return CheckInDraft(
      mood: mood,
      category: category == null || category.isEmpty ? null : category,
    );
  }

  Future<void> saveToday({required int mood, String? category}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dayKey, _dayKeyFor(DateTime.now()));
    await prefs.setInt(_moodKey, mood);
    if (category == null || category.isEmpty) {
      await prefs.remove(_categoryKey);
    } else {
      await prefs.setString(_categoryKey, category);
    }
  }

  /// Record a confirmed check-in for [day] (defaults to today). The latest
  /// save for a day wins — re-saving updates that day's entry.
  Future<void> recordEntry({
    required int mood,
    String? category,
    DateTime? day,
  }) async {
    final entry = CheckInEntry(
      day: CheckInEntry.dayOnly(day ?? DateTime.now()),
      mood: mood,
      category: category,
    );
    final history = await loadHistory();
    final next = [
      entry,
      ...history.where((e) => e.day != entry.day),
    ]..sort((a, b) => a.day.compareTo(b.day));
    // Keep a rolling window so the store cannot grow unbounded.
    final trimmed = next.length > 120 ? next.sublist(next.length - 120) : next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  /// All stored entries, oldest → newest.
  Future<List<CheckInEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => CheckInEntry.tryParse(Map<String, dynamic>.from(e)))
          .whereType<CheckInEntry>()
          .toList()
        ..sort((a, b) => a.day.compareTo(b.day));
    } catch (_) {
      return const [];
    }
  }

  /// One entry per day for the last [days] days (ending today). Days with no
  /// check-in are omitted — callers can spot gaps by comparing [day] values.
  Future<List<CheckInEntry>> loadLastDays(int days) async {
    final cutoff = CheckInEntry.dayOnly(
      DateTime.now().subtract(Duration(days: days - 1)),
    );
    final history = await loadHistory();
    return history.where((e) => !e.day.isBefore(cutoff)).toList();
  }

  String _dayKeyFor(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$d';
  }
}
