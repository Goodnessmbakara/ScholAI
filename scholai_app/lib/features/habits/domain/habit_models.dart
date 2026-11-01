import 'package:equatable/equatable.dart';

/// Supported urge areas. Self-harm is intentionally excluded — crisis stays on `/crisis`.
enum HabitKind {
  smoking,
  pornUrges,
  doomscrolling,
  custom;

  String get id => name;

  String get label => switch (this) {
        HabitKind.smoking => 'Smoking',
        HabitKind.pornUrges => 'Porn / compulsive urges',
        HabitKind.doomscrolling => 'Doomscrolling',
        HabitKind.custom => 'Something else',
      };

  String get shortHint => switch (this) {
        HabitKind.smoking => 'Cigarettes, vapes, or nicotine urges',
        HabitKind.pornUrges => 'Porn or compulsive sexual urges — no shame, just notice',
        HabitKind.doomscrolling => 'Endless feed / phone rabbit holes',
        HabitKind.custom => 'Name your own — alcohol, weed, gambling, gaming, anything',
      };

  static HabitKind? tryParse(String id) {
    for (final kind in HabitKind.values) {
      if (kind.id == id) return kind;
    }
    return null;
  }
}

/// Stop tracks days since the last counted slip. Cut down tracks days you showed up.
enum HabitAim {
  stop,
  cutDown;

  String get id => name;

  String get label => switch (this) {
        HabitAim.stop => 'Stop',
        HabitAim.cutDown => 'Cut down',
      };

  String get hint => switch (this) {
        HabitAim.stop => 'A slip ends this run. Your best run stays.',
        HabitAim.cutDown => 'Showing up keeps the run. A slip is logged, not a reset.',
      };

  static HabitAim? tryParse(String id) {
    for (final aim in HabitAim.values) {
      if (aim.id == id) return aim;
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

/// What was going on just before the urge. Used for the pattern card.
enum UrgeTrigger {
  boredom,
  stress,
  loneliness,
  habitLoop,
  other;

  String get id => name;

  String get label => switch (this) {
        UrgeTrigger.boredom => 'Boredom',
        UrgeTrigger.stress => 'Stress',
        UrgeTrigger.loneliness => 'Loneliness',
        UrgeTrigger.habitLoop => 'Just the habit',
        UrgeTrigger.other => 'Something else',
      };

  String get patternPhrase => switch (this) {
        UrgeTrigger.boredom => 'boredom',
        UrgeTrigger.stress => 'stress',
        UrgeTrigger.loneliness => 'loneliness',
        UrgeTrigger.habitLoop => 'the habit itself',
        UrgeTrigger.other => 'something else',
      };

  static UrgeTrigger? tryParse(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final trigger in UrgeTrigger.values) {
      if (trigger.id == id) return trigger;
    }
    return null;
  }
}

/// Only meaningful for porn urges. Masturbation without porn can be left off the streak.
enum PornAct {
  none,
  porn,
  masturbationOnly;

  String get id => name;

  static PornAct? tryParse(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final act in PornAct.values) {
      if (act.id == id) return act;
    }
    return null;
  }
}

class HabitPlan extends Equatable {
  final HabitKind habit;
  final HabitAim aim;
  final bool masturbationCountsAsSlip;
  final String reason;
  final DateTime startedAt;
  final String customLabel;

  /// If-then counter-move the user picked for their top trigger.
  final String counterMove;

  /// Post-slip debrief answer — "what I'll try next time".
  final String nextTryNote;

  /// Optional daily cost (₦) — fuels the "saved so far" line on Stop aims.
  final double dailyCost;

  const HabitPlan({
    required this.habit,
    required this.aim,
    required this.masturbationCountsAsSlip,
    required this.reason,
    required this.startedAt,
    this.customLabel = '',
    this.counterMove = '',
    this.nextTryNote = '',
    this.dailyCost = 0,
  });

  /// What to show the user — the typed name for custom areas.
  String get displayName =>
      habit == HabitKind.custom && customLabel.trim().isNotEmpty
          ? customLabel.trim()
          : habit.label;

  factory HabitPlan.fallback(HabitKind habit, {DateTime? now}) {
    return HabitPlan(
      habit: habit,
      aim: HabitAim.cutDown,
      masturbationCountsAsSlip: false,
      reason: '',
      startedAt: now ?? DateTime.now(),
    );
  }

  HabitPlan copyWith({
    HabitAim? aim,
    bool? masturbationCountsAsSlip,
    String? reason,
    DateTime? startedAt,
    String? customLabel,
    String? counterMove,
    String? nextTryNote,
    double? dailyCost,
  }) {
    return HabitPlan(
      habit: habit,
      aim: aim ?? this.aim,
      masturbationCountsAsSlip:
          masturbationCountsAsSlip ?? this.masturbationCountsAsSlip,
      reason: reason ?? this.reason,
      startedAt: startedAt ?? this.startedAt,
      customLabel: customLabel ?? this.customLabel,
      counterMove: counterMove ?? this.counterMove,
      nextTryNote: nextTryNote ?? this.nextTryNote,
      dailyCost: dailyCost ?? this.dailyCost,
    );
  }

  Map<String, dynamic> toJson() => {
        'habit': habit.id,
        'aim': aim.id,
        'masturbationCountsAsSlip': masturbationCountsAsSlip,
        'reason': reason,
        'startedAt': startedAt.toIso8601String(),
        if (customLabel.isNotEmpty) 'customLabel': customLabel,
        if (counterMove.isNotEmpty) 'counterMove': counterMove,
        if (nextTryNote.isNotEmpty) 'nextTryNote': nextTryNote,
        if (dailyCost > 0) 'dailyCost': dailyCost,
      };

  factory HabitPlan.fromJson(Map<String, dynamic> json) {
    final habit =
        HabitKind.tryParse(json['habit'] as String? ?? '') ?? HabitKind.smoking;
    return HabitPlan(
      habit: habit,
      aim: HabitAim.tryParse(json['aim'] as String? ?? '') ?? HabitAim.cutDown,
      masturbationCountsAsSlip: json['masturbationCountsAsSlip'] == true,
      reason: json['reason'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
      customLabel: json['customLabel'] as String? ?? '',
      counterMove: json['counterMove'] as String? ?? '',
      nextTryNote: json['nextTryNote'] as String? ?? '',
      dailyCost: (json['dailyCost'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        habit,
        aim,
        masturbationCountsAsSlip,
        reason,
        startedAt,
        customLabel,
        counterMove,
        nextTryNote,
        dailyCost,
      ];
}

/// Competing responses per trigger — "when X, do Y instead".
const kCounterMoves = <UrgeTrigger, List<String>>{
  UrgeTrigger.boredom: [
    'Take a 10-minute walk',
    'Do 20 push-ups or squats',
    'Make tea — no phone',
  ],
  UrgeTrigger.stress: [
    '4-7-8 breathing, four rounds',
    'Step outside for two minutes of air',
    'Write the stress down before anything else',
  ],
  UrgeTrigger.loneliness: [
    'Text someone you trust',
    'Go where people are — class, hall, café',
    'Call a friend instead of scrolling',
  ],
  UrgeTrigger.habitLoop: [
    'Change rooms right now',
    'Hold something else — pen, stress ball',
    'Read one page of anything',
  ],
  UrgeTrigger.other: [
    'Drink a glass of water slowly',
    'Set a 10-minute timer and just wait',
    'Move your body — any way',
  ],
};

/// Environment-design tips per area — friction beats willpower.
const kFrictionTips = <HabitKind, List<String>>{
  HabitKind.smoking: [
    'Don\'t carry them — leave the pack behind',
    'Tell one person you\'re cutting down',
  ],
  HabitKind.pornUrges: [
    'Charge the phone outside the bedroom',
    'Turn on a DNS/content filter',
  ],
  HabitKind.doomscrolling: [
    'Log out or move the app off your home screen',
    'Set a grayscale shortcut for nights',
  ],
  HabitKind.custom: [
    'Change one thing in your space that feeds the urge',
  ],
};

class UrgeLog extends Equatable {
  final String id;
  final HabitKind habit;
  final int intensity; // 1–5
  final UrgeOutcome outcome;
  final DateTime loggedAt;
  final String? note;
  final UrgeTrigger? trigger;
  final PornAct pornAct;
  final bool countsAsSlip;

  const UrgeLog({
    required this.id,
    required this.habit,
    required this.intensity,
    required this.outcome,
    required this.loggedAt,
    this.note,
    this.trigger,
    this.pornAct = PornAct.none,
    this.countsAsSlip = false,
  });

  String get outcomeLabel {
    if (outcome == UrgeOutcome.rodeItOut) return UrgeOutcome.rodeItOut.label;
    if (!countsAsSlip && pornAct == PornAct.masturbationOnly) {
      return 'Logged, not a slip';
    }
    return UrgeOutcome.actedOn.label;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'habit': habit.id,
        'intensity': intensity,
        'outcome': outcome.id,
        'loggedAt': loggedAt.toIso8601String(),
        if (note != null && note!.isNotEmpty) 'note': note,
        if (trigger != null) 'trigger': trigger!.id,
        if (pornAct != PornAct.none) 'pornAct': pornAct.id,
        'countsAsSlip': countsAsSlip,
      };

  factory UrgeLog.fromJson(Map<String, dynamic> json) {
    final habit =
        HabitKind.tryParse(json['habit'] as String? ?? '') ?? HabitKind.smoking;
    final outcome = UrgeOutcome.tryParse(json['outcome'] as String? ?? '') ??
        UrgeOutcome.rodeItOut;
    final intensity = (json['intensity'] as num?)?.toInt().clamp(1, 5) ?? 3;
    final pornAct = PornAct.tryParse(json['pornAct'] as String?) ?? PornAct.none;
    final countsAsSlip = json.containsKey('countsAsSlip')
        ? json['countsAsSlip'] == true
        : outcome == UrgeOutcome.actedOn;
    return UrgeLog(
      id: json['id'] as String? ?? '',
      habit: habit,
      intensity: intensity,
      outcome: outcome,
      loggedAt: DateTime.tryParse(json['loggedAt'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
      trigger: UrgeTrigger.tryParse(json['trigger'] as String?),
      pornAct: pornAct,
      countsAsSlip: countsAsSlip,
    );
  }

  @override
  List<Object?> get props => [
        id,
        habit,
        intensity,
        outcome,
        loggedAt,
        note,
        trigger,
        pornAct,
        countsAsSlip,
      ];
}

class HabitStats extends Equatable {
  final int riddenOutTotal;
  final int actedOnTotal;
  final int currentStreakDays;
  final int bestStreakDays;
  final int todayLogCount;
  final bool abstinenceStreak;

  const HabitStats({
    required this.riddenOutTotal,
    required this.actedOnTotal,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.todayLogCount,
    required this.abstinenceStreak,
  });

  static const empty = HabitStats(
    riddenOutTotal: 0,
    actedOnTotal: 0,
    currentStreakDays: 0,
    bestStreakDays: 0,
    todayLogCount: 0,
    abstinenceStreak: false,
  );

  @override
  List<Object?> get props => [
        riddenOutTotal,
        actedOnTotal,
        currentStreakDays,
        bestStreakDays,
        todayLogCount,
        abstinenceStreak,
      ];
}

class UrgePattern extends Equatable {
  final bool ready;
  final int loggedCount;
  final String? timeLabel;
  final UrgeTrigger? topTrigger;

  const UrgePattern({
    required this.ready,
    required this.loggedCount,
    this.timeLabel,
    this.topTrigger,
  });

  static const locked = UrgePattern(ready: false, loggedCount: 0);

  String get summary {
    if (!ready || timeLabel == null) {
      final left = (7 - loggedCount).clamp(0, 7);
      return 'Log $left more and a pattern can show — usual time, and what came first.';
    }
    final trigger = topTrigger;
    if (trigger == null) {
      return 'Most of these land in the $timeLabel.';
    }
    return 'Most of these land in the $timeLabel, often after ${trigger.patternPhrase}.';
  }

  @override
  List<Object?> get props => [ready, loggedCount, timeLabel, topTrigger];
}

/// Optional cloud shape (not wired yet):
/// `/users/{uid}/habits/{habitId}` — selected kinds + createdAt
/// `/users/{uid}/urge_logs/{logId}` — urge fields mirroring [UrgeLog.toJson]
abstract final class HabitFirestorePaths {
  static String habits(String uid) => 'users/$uid/habits';
  static String urgeLogs(String uid) => 'users/$uid/urge_logs';
}
