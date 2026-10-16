import 'package:equatable/equatable.dart';

/// Supported urge areas. Self-harm is intentionally excluded — crisis stays on `/crisis`.
enum HabitKind {
  smoking,
  pornUrges,
  doomscrolling;

  String get id => name;

  String get label => switch (this) {
        HabitKind.smoking => 'Smoking',
        HabitKind.pornUrges => 'Porn / compulsive urges',
        HabitKind.doomscrolling => 'Doomscrolling',
      };

  String get shortHint => switch (this) {
        HabitKind.smoking => 'Cigarettes, vapes, or nicotine urges',
        HabitKind.pornUrges => 'Porn or compulsive sexual urges — no shame, just notice',
        HabitKind.doomscrolling => 'Endless feed / phone rabbit holes',
      };

  static HabitKind? tryParse(String id) {
    for (final kind in HabitKind.values) {
      if (kind.id == id) return kind;
    }
    return null;
  }
}

enum UrgeOutcome {
  rodeItOut,
  actedOn;

  String get id => name;

  String get label => switch (this) {
        UrgeOutcome.rodeItOut => 'Rode it out',
        UrgeOutcome.actedOn => 'Acted on it',
      };

  static UrgeOutcome? tryParse(String id) {
    for (final o in UrgeOutcome.values) {
      if (o.id == id) return o;
    }
    return null;
  }
}

class UrgeLog extends Equatable {
  final String id;
  final HabitKind habit;
  final int intensity; // 1–5
  final UrgeOutcome outcome;
  final DateTime loggedAt;
  final String? note;

  const UrgeLog({
    required this.id,
    required this.habit,
    required this.intensity,
    required this.outcome,
    required this.loggedAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'habit': habit.id,
        'intensity': intensity,
        'outcome': outcome.id,
        'loggedAt': loggedAt.toIso8601String(),
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  factory UrgeLog.fromJson(Map<String, dynamic> json) {
    final habit = HabitKind.tryParse(json['habit'] as String? ?? '') ?? HabitKind.smoking;
    final outcome =
        UrgeOutcome.tryParse(json['outcome'] as String? ?? '') ?? UrgeOutcome.rodeItOut;
    final intensity = (json['intensity'] as num?)?.toInt().clamp(1, 5) ?? 3;
    return UrgeLog(
      id: json['id'] as String? ?? '',
      habit: habit,
      intensity: intensity,
      outcome: outcome,
      loggedAt: DateTime.tryParse(json['loggedAt'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, habit, intensity, outcome, loggedAt, note];
}

class HabitStats extends Equatable {
  final int riddenOutTotal;
  final int actedOnTotal;
  final int currentStreakDays;
  final int todayLogCount;

  const HabitStats({
    required this.riddenOutTotal,
    required this.actedOnTotal,
    required this.currentStreakDays,
    required this.todayLogCount,
  });

  static const empty = HabitStats(
    riddenOutTotal: 0,
    actedOnTotal: 0,
    currentStreakDays: 0,
    todayLogCount: 0,
  );

  @override
  List<Object?> get props =>
      [riddenOutTotal, actedOnTotal, currentStreakDays, todayLogCount];
}

/// Optional cloud shape (not wired yet):
/// `/users/{uid}/habits/{habitId}` — selected kinds + createdAt
/// `/users/{uid}/urge_logs/{logId}` — urge fields mirroring [UrgeLog.toJson]
abstract final class HabitFirestorePaths {
  static String habits(String uid) => 'users/$uid/habits';
  static String urgeLogs(String uid) => 'users/$uid/urge_logs';
}
