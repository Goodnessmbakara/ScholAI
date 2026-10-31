import 'package:equatable/equatable.dart';
import 'package:scholai_app/features/habits/domain/habit_models.dart';

enum HabitStatus { initial, loading, ready, failure }

class HabitState extends Equatable {
  final HabitStatus status;
  final bool setupDone;
  final List<HabitKind> selectedHabits;
  final List<HabitPlan> plans;
  final List<UrgeLog> logs;
  final HabitStats stats;
  final String? reflectionPrompt;
  final bool reflectionLoading;
  final String? errorMessage;

  const HabitState({
    this.status = HabitStatus.initial,
    this.setupDone = false,
    this.selectedHabits = const [],
    this.plans = const [],
    this.logs = const [],
    this.stats = HabitStats.empty,
    this.reflectionPrompt,
    this.reflectionLoading = false,
    this.errorMessage,
  });

  HabitState copyWith({
    HabitStatus? status,
    bool? setupDone,
    List<HabitKind>? selectedHabits,
    List<HabitPlan>? plans,
    List<UrgeLog>? logs,
    HabitStats? stats,
    String? reflectionPrompt,
    bool clearReflection = false,
    bool? reflectionLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HabitState(
      status: status ?? this.status,
      setupDone: setupDone ?? this.setupDone,
      selectedHabits: selectedHabits ?? this.selectedHabits,
      plans: plans ?? this.plans,
      logs: logs ?? this.logs,
      stats: stats ?? this.stats,
      reflectionPrompt:
          clearReflection ? null : (reflectionPrompt ?? this.reflectionPrompt),
      reflectionLoading: reflectionLoading ?? this.reflectionLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  HabitPlan planFor(HabitKind habit) {
    for (final plan in plans) {
      if (plan.habit == habit) return plan;
    }
    return HabitPlan.fallback(habit);
  }

  @override
  List<Object?> get props => [
        status,
        setupDone,
        selectedHabits,
        plans,
        logs,
        stats,
        reflectionPrompt,
        reflectionLoading,
        errorMessage,
      ];
}
