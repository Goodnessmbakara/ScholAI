import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholai_app/features/habits/domain/habit_models.dart';

/// Local-first persistence for habit selection and urge logs.
///
/// Future sync (optional): mirror to
/// `users/{uid}/habits/{habitId}` and `users/{uid}/urge_logs/{logId}`.
class HabitLocalStore {
  HabitLocalStore._();
  static final instance = HabitLocalStore._();

  static const _selectedKey = 'habits_selected_kinds';
  static const _logsKey = 'habits_urge_logs';
  static const _setupDoneKey = 'habits_setup_done';
  static const _plansKey = 'habits_plans_v1';

  Future<bool> isSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupDoneKey) ?? false;
  }

  Future<List<HabitKind>> loadSelectedHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_selectedKey) ?? const [];
    return raw.map(HabitKind.tryParse).whereType<HabitKind>().toList();
  }

  Future<void> saveSelectedHabits(List<HabitKind> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _selectedKey,
      habits.map((h) => h.id).toList(),
    );
    await prefs.setBool(_setupDoneKey, habits.isNotEmpty);
  }

  Future<List<UrgeLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_logsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => UrgeLog.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    } catch (_) {
      return const [];
    }
  }

  Future<void> addLog(UrgeLog log) async {
    final logs = await loadLogs();
    logs.insert(0, log);
    await _persistLogs(logs);
  }

  Future<void> _persistLogs(List<UrgeLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _logsKey,
      jsonEncode(logs.map((l) => l.toJson()).toList()),
    );
  }

  Future<List<HabitPlan>> loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_plansKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => HabitPlan.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> savePlans(List<HabitPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _plansKey,
      jsonEncode(plans.map((plan) => plan.toJson()).toList()),
    );
  }
}
