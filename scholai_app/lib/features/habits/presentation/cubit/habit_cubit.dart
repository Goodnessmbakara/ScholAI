import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:scholai_app/core/services/gemini_service.dart';
import 'package:scholai_app/features/habits/data/habit_local_store.dart';
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
      if (isClosed) return;
      emit(
        state.copyWith(
          status: HabitStatus.ready,
          selectedHabits: selected,
          setupDone: setupDone && selected.isNotEmpty,
          logs: logs,
          stats: _store.computeStats(logs),
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
    if (isClosed) return;
    emit(
      state.copyWith(
        selectedHabits: list,
        setupDone: list.isNotEmpty,
        status: HabitStatus.ready,
        clearError: true,
      ),
    );
  }

  Future<void> logUrge({
    required HabitKind habit,
    required int intensity,
    required UrgeOutcome outcome,
    String? note,
  }) async {
    final log = UrgeLog(
      id: _uuid.v4(),
      habit: habit,
      intensity: intensity.clamp(1, 5),
      outcome: outcome,
      loggedAt: DateTime.now(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );
    await _store.addLog(log);
    final logs = await _store.loadLogs();
    if (isClosed) return;
    emit(
      state.copyWith(
        logs: logs,
        stats: _store.computeStats(logs),
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
        final ai = await _gemini.generateUrgeReflection(
          habitLabel: habit.label,
          intensity: intensity,
          rodeItOut: outcome == UrgeOutcome.rodeItOut,
        );
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
}
