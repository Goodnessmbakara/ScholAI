import 'package:flutter_test/flutter_test.dart';
import 'package:scholai_app/features/habits/domain/habit_insights.dart';
import 'package:scholai_app/features/habits/domain/habit_models.dart';

void main() {
  final start = DateTime(2026, 1, 1, 8);

  HabitPlan planFor(HabitKind habit, {HabitAim aim = HabitAim.stop, bool masturbation = false}) {
    return HabitPlan(
      habit: habit,
      aim: aim,
      masturbationCountsAsSlip: masturbation,
      reason: '',
      startedAt: start,
    );
  }

  UrgeLog entry({
    required DateTime at,
    HabitKind habit = HabitKind.smoking,
    UrgeOutcome outcome = UrgeOutcome.rodeItOut,
    bool slip = false,
    PornAct pornAct = PornAct.none,
    UrgeTrigger? trigger,
  }) {
    return UrgeLog(
      id: at.toIso8601String(),
      habit: habit,
      intensity: 3,
      outcome: outcome,
      loggedAt: at,
      pornAct: pornAct,
      countsAsSlip: slip,
      trigger: trigger,
    );
  }

  test('a slip zeros the current run and keeps the best', () {
    final stats = computeHabitStats(
      logs: [
        entry(at: DateTime(2026, 1, 2, 9)),
        entry(
          at: DateTime(2026, 1, 5, 9),
          outcome: UrgeOutcome.actedOn,
          slip: true,
        ),
      ],
      habit: HabitKind.smoking,
      plan: planFor(HabitKind.smoking),
      now: DateTime(2026, 1, 5, 12),
    );

    expect(stats.currentStreakDays, 0);
    expect(stats.bestStreakDays, 4);
    expect(stats.abstinenceStreak, isTrue);
  });

  test('days after a slip count again without touching the best', () {
    final stats = computeHabitStats(
      logs: [
        entry(
          at: DateTime(2026, 1, 1, 9),
          outcome: UrgeOutcome.actedOn,
          slip: true,
        ),
      ],
      habit: HabitKind.smoking,
      plan: planFor(HabitKind.smoking),
      now: DateTime(2026, 1, 4, 12),
    );

    expect(stats.currentStreakDays, 3);
    expect(stats.bestStreakDays, 3);
  });

  test('masturbation without porn is not a slip unless they say so', () {
    final stats = computeHabitStats(
      logs: [
        entry(
          at: DateTime(2026, 1, 3, 21),
          habit: HabitKind.pornUrges,
          outcome: UrgeOutcome.actedOn,
          pornAct: PornAct.masturbationOnly,
        ),
      ],
      habit: HabitKind.pornUrges,
      plan: planFor(HabitKind.pornUrges),
      now: DateTime(2026, 1, 3, 22),
    );

    expect(stats.currentStreakDays, 3);
    expect(stats.bestStreakDays, 3);
  });

  test('cutting down keeps the check-in run through a slip', () {
    final stats = computeHabitStats(
      logs: [
        entry(at: DateTime(2026, 1, 1, 9), habit: HabitKind.doomscrolling),
        entry(
          at: DateTime(2026, 1, 2, 9),
          habit: HabitKind.doomscrolling,
          outcome: UrgeOutcome.actedOn,
          slip: true,
        ),
        entry(at: DateTime(2026, 1, 3, 9), habit: HabitKind.doomscrolling),
      ],
      habit: HabitKind.doomscrolling,
      plan: planFor(HabitKind.doomscrolling, aim: HabitAim.cutDown),
      now: DateTime(2026, 1, 3, 18),
    );

    expect(stats.currentStreakDays, 3);
    expect(stats.bestStreakDays, 3);
    expect(stats.abstinenceStreak, isFalse);
  });

  test('pattern waits for seven logs, then names time and trigger', () {
    final early = computeUrgePattern(
      List.generate(
        6,
        (i) => entry(
          at: DateTime(2026, 1, 1, 19, i),
          trigger: UrgeTrigger.stress,
        ),
      ),
      HabitKind.smoking,
    );
    expect(early.ready, isFalse);

    final ready = computeUrgePattern(
      List.generate(
        7,
        (i) => entry(
          at: DateTime(2026, 1, 1, 19, i),
          trigger: UrgeTrigger.stress,
        ),
      ),
      HabitKind.smoking,
    );
    expect(ready.ready, isTrue);
    expect(ready.timeLabel, 'evening');
    expect(ready.topTrigger, UrgeTrigger.stress);
    expect(ready.summary, contains('evening'));
    expect(ready.summary, contains('stress'));
  });
}
