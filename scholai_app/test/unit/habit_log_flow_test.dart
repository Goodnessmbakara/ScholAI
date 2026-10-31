import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholai_app/features/habits/data/habit_local_store.dart';
import 'package:scholai_app/features/habits/domain/habit_models.dart';
import 'package:scholai_app/features/habits/presentation/cubit/habit_cubit.dart';

/// End-to-end-ish coverage of the "Save log" path:
/// HabitsScreen/UrgeTimerScreen -> HabitCubit.logUrge -> HabitLocalStore ->
/// SharedPreferences -> reload -> state + stats.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save log persists to prefs, survives a reload, and updates stats',
      () async {
    final cubit = HabitCubit();

    await cubit.saveSelectedHabits({HabitKind.smoking});
    expect(cubit.state.setupDone, isTrue);

    // Same call HabitsScreen._submitLog makes.
    await cubit.logUrge(
      habit: HabitKind.smoking,
      intensity: 4,
      outcome: UrgeOutcome.rodeItOut,
      trigger: UrgeTrigger.stress,
    );

    // Persisted in SharedPreferences, not just cubit state.
    final stored = await HabitLocalStore.instance.loadLogs();
    expect(stored, hasLength(1));
    expect(stored.first.habit, HabitKind.smoking);
    expect(stored.first.intensity, 4);
    expect(stored.first.trigger, UrgeTrigger.stress);
    expect(stored.first.countsAsSlip, isFalse);

    // Fresh cubit on a cold start sees the same log.
    final cold = HabitCubit();
    await cold.load();
    expect(cold.state.logs, hasLength(1));

    // Same call UrgeTimerScreen._save makes — a slip.
    await cubit.logUrge(
      habit: HabitKind.smoking,
      intensity: 5,
      outcome: UrgeOutcome.actedOn,
    );

    expect(cubit.state.logs, hasLength(2));
    expect(cubit.state.logs.first.countsAsSlip, isTrue);
    expect(cubit.state.stats.riddenOutTotal, 1);
    expect(cubit.state.stats.actedOnTotal, 1);
    // "Stop" aim would reset the run; fallback plan is cutDown so a
    // same-day slip still counts toward todayLogCount.
    expect(cubit.state.stats.todayLogCount, 2);
  });
}
