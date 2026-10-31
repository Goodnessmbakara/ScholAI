import 'package:scholai_app/features/habits/domain/habit_models.dart';

const patternLogThreshold = 7;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool slipCounts({
  required UrgeOutcome outcome,
  required HabitKind habit,
  required PornAct pornAct,
  required HabitPlan plan,
}) {
  if (outcome != UrgeOutcome.actedOn) return false;
  if (habit == HabitKind.pornUrges &&
      pornAct == PornAct.masturbationOnly &&
      !plan.masturbationCountsAsSlip) {
    return false;
  }
  return true;
}

HabitStats computeHabitStats({
  required List<UrgeLog> logs,
  required HabitKind habit,
  required HabitPlan plan,
  required DateTime now,
}) {
  final mine = logs.where((log) => log.habit == habit).toList();
  final today = dateOnly(now);
  final ridden = mine.where((log) => log.outcome == UrgeOutcome.rodeItOut).length;
  final acted = mine.where((log) => log.outcome == UrgeOutcome.actedOn).length;
  final todayCount = mine.where((log) => dateOnly(log.loggedAt) == today).length;

  final streak = plan.aim == HabitAim.stop
      ? _abstinenceStreak(mine, plan.startedAt, today)
      : _checkInStreak(mine, today);

  return HabitStats(
    riddenOutTotal: ridden,
    actedOnTotal: acted,
    currentStreakDays: streak.$1,
    bestStreakDays: streak.$2,
    todayLogCount: todayCount,
    abstinenceStreak: plan.aim == HabitAim.stop,
  );
}

UrgePattern computeUrgePattern(List<UrgeLog> logs, HabitKind habit) {
  final mine = logs.where((log) => log.habit == habit).toList();
  if (mine.length < patternLogThreshold) {
    return UrgePattern(ready: false, loggedCount: mine.length);
  }

  final timeLabel = _topTimeLabel(mine);
  final trigger = _topTrigger(mine);
  return UrgePattern(
    ready: true,
    loggedCount: mine.length,
    timeLabel: timeLabel,
    topTrigger: trigger,
  );
}

(int, int) _abstinenceStreak(
  List<UrgeLog> logs,
  DateTime startedAt,
  DateTime today,
) {
  final start = dateOnly(startedAt);
  final anchorStart = start.isAfter(today) ? today : start;
  final slips = logs
      .where((log) => log.countsAsSlip)
      .map((log) => dateOnly(log.loggedAt))
      .where((day) => !day.isBefore(anchorStart) && !day.isAfter(today))
      .toSet()
      .toList()
    ..sort();

  var best = 0;
  var anchor = anchorStart.subtract(const Duration(days: 1));
  for (final slip in slips) {
    final beforeSlip = slip.difference(anchor).inDays - 1;
    if (beforeSlip > best) best = beforeSlip;
    anchor = slip;
  }

  final current = today.difference(anchor).inDays;
  if (current > best) best = current;
  return (current < 0 ? 0 : current, best < 0 ? 0 : best);
}

(int, int) _checkInStreak(List<UrgeLog> logs, DateTime today) {
  final days = logs.map((log) => dateOnly(log.loggedAt)).toSet();
  if (days.isEmpty) return (0, 0);

  final sorted = days.toList()..sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < sorted.length; i++) {
    final gap = sorted[i].difference(sorted[i - 1]).inDays;
    if (gap == 1) {
      run++;
      if (run > best) best = run;
    } else if (gap > 1) {
      run = 1;
    }
  }

  var cursor = today;
  if (!days.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) return (0, best);
  }

  var current = 0;
  while (days.contains(cursor)) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  if (current > best) best = current;
  return (current, best);
}

String _topTimeLabel(List<UrgeLog> logs) {
  final counts = <String, int>{};
  for (final log in logs) {
    final label = _timeBucket(log.loggedAt.hour);
    counts[label] = (counts[label] ?? 0) + 1;
  }
  const order = ['morning', 'afternoon', 'evening', 'night'];
  var bestLabel = order.first;
  var bestCount = -1;
  for (final label in order) {
    final count = counts[label] ?? 0;
    if (count > bestCount) {
      bestCount = count;
      bestLabel = label;
    }
  }
  return bestLabel;
}

UrgeTrigger? _topTrigger(List<UrgeLog> logs) {
  final tagged = logs.where((log) => log.trigger != null).toList();
  if (tagged.isEmpty) return null;

  var best = tagged.first.trigger!;
  var bestCount = 0;
  for (final trigger in UrgeTrigger.values) {
    final count = tagged.where((log) => log.trigger == trigger).length;
    if (count > bestCount) {
      bestCount = count;
      best = trigger;
    }
  }
  return bestCount == 0 ? null : best;
}

String _timeBucket(int hour) {
  if (hour >= 5 && hour < 12) return 'morning';
  if (hour >= 12 && hour < 17) return 'afternoon';
  if (hour >= 17 && hour < 22) return 'evening';
  return 'night';
}
