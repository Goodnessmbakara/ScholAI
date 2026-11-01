import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:scholai_app/core/services/gemini_service.dart';
import 'package:scholai_app/features/habits/data/habit_local_store.dart';
import 'package:scholai_app/features/habits/domain/habit_insights.dart';
import 'package:scholai_app/features/habits/domain/habit_models.dart';
import 'package:scholai_app/features/habits/presentation/cubit/habit_state.dart';

class HabitCubit extends Cubit<HabitState> {
  HabitCubit({
    HabitLocalStore? store,
    GeminiService? gemini,
  })  : _store = store ?? HabitLocalStore.instance,
        _gemini = gemini ?? GeminiService.instance,
        super(const HabitState());

  final HabitLocalStore _store;
  final GeminiService _gemini;
  final _uuid = const Uuid();

  static const staticPrompts = [
    'What usually shows up right before this urge — boredom, stress, loneliness, something else?',
    'If this urge had a volume dial, what turned it up today?',
    'What would “riding it out for 10 minutes” look like for you right now?',
    'Is there a kinder way to meet the need underneath this urge?',
    'What helped last time, even a little?',
  ];

  Future<void> load() async {
    emit(state.copyWith(status: HabitStatus.loading, clearError: true));
    try {
      final selected = await _store.loadSelectedHabits();
      final setupDone = await _store.isSetupDone();
      final logs = await _store.loadLogs();
      final plans = await _ensurePlans(selected, await _store.loadPlans());
      if (isClosed) return;
      emit(
        state.copyWith(
          status: HabitStatus.ready,
          selectedHabits: selected,
          plans: plans,
          setupDone: setupDone && selected.isNotEmpty,
          logs: logs,
          stats: _statsFor(selected, plans, logs),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: HabitStatus.failure,
          errorMessage: 'Could not load habit data.',
        ),
      );
    }
  }

  Future<void> saveSelectedHabits(Set<HabitKind> habits) async {
    final list = habits.toList();
    await _store.saveSelectedHabits(list);
    final plans = await _ensurePlans(list, state.plans);
    if (isClosed) return;
    emit(
      state.copyWith(
        selectedHabits: list,
        plans: plans,
        setupDone: list.isNotEmpty,
        status: HabitStatus.ready,
        stats: _statsFor(list, plans, state.logs),
        clearError: true,
      ),
    );
  }

  Future<void> savePlan(HabitPlan plan) async {
    final next = [
      for (final existing in state.plans)
        if (existing.habit != plan.habit) existing,
      plan,
    ];
    await _store.savePlans(next);
    if (isClosed) return;
    emit(
      state.copyWith(
        plans: next,
        stats: _statsFor(state.selectedHabits, next, state.logs),
      ),
    );
  }

  Future<void> logUrge({
    required HabitKind habit,
    required int intensity,
    required UrgeOutcome outcome,
    UrgeTrigger? trigger,
    PornAct pornAct = PornAct.none,
    String? note,
  }) async {
    final plan = _planOrFallback(habit);
    final log = UrgeLog(
      id: _uuid.v4(),
      habit: habit,
      intensity: intensity.clamp(1, 5),
      outcome: outcome,
      loggedAt: DateTime.now(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      trigger: trigger,
      pornAct: habit == HabitKind.pornUrges ? pornAct : PornAct.none,
      countsAsSlip: slipCounts(
        outcome: outcome,
        habit: habit,
        pornAct: pornAct,
        plan: plan,
      ),
    );
    await _store.addLog(log);
    final logs = await _store.loadLogs();
    if (isClosed) return;
    emit(
      state.copyWith(
        logs: logs,
        stats: _statsFor(state.selectedHabits, state.plans, logs),
        clearReflection: true,
      ),
    );
  }

  Future<void> requestReflection({
    required HabitKind habit,
    required int intensity,
    required UrgeOutcome outcome,
  }) async {
    emit(state.copyWith(reflectionLoading: true, clearReflection: true));

    String prompt;
    if (_gemini.hasApiKey) {
      try {
        // Timeout keeps a stalled Gemini call from spinning forever —
        // the static prompts are the intended fallback.
        final ai = await _gemini
            .generateUrgeReflection(
              habitLabel: habit.label,
              intensity: intensity,
              rodeItOut: outcome == UrgeOutcome.rodeItOut,
            )
            .timeout(const Duration(seconds: 15));
        prompt = (ai != null && ai.isNotEmpty)
            ? ai
            : _staticPromptFor(habit, intensity, outcome);
      } catch (_) {
        prompt = _staticPromptFor(habit, intensity, outcome);
      }
    } else {
      prompt = _staticPromptFor(habit, intensity, outcome);
    }

    if (isClosed) return;
    emit(state.copyWith(reflectionLoading: false, reflectionPrompt: prompt));
  }

  String _staticPromptFor(HabitKind habit, int intensity, UrgeOutcome outcome) {
    final seed = habit.index + intensity + outcome.index + DateTime.now().day;
    return staticPrompts[seed % staticPrompts.length];
  }

  HabitPlan _planOrFallback(HabitKind habit) {
    for (final plan in state.plans) {
      if (plan.habit == habit) return plan;
    }
    return HabitPlan.fallback(habit);
  }

  Future<List<HabitPlan>> _ensurePlans(
    List<HabitKind> selected,
    List<HabitPlan> existing,
  ) async {
    final next = [...existing];
    var changed = false;
    for (final kind in selected) {
      if (next.any((plan) => plan.habit == kind)) continue;
      next.add(HabitPlan.fallback(kind));
      changed = true;
    }
    if (changed) await _store.savePlans(next);
    return next;
  }

  HabitStats _statsFor(
    List<HabitKind> selected,
    List<HabitPlan> plans,
    List<UrgeLog> logs,
  ) {
    if (selected.isEmpty) return HabitStats.empty;
    final habit = selected.first;
    HabitPlan? plan;
    for (final item in plans) {
      if (item.habit == habit) {
        plan = item;
        break;
      }
    }
    return computeHabitStats(
      logs: logs,
      habit: habit,
      plan: plan ?? HabitPlan.fallback(habit),
      now: DateTime.now(),
    );
  }
}
