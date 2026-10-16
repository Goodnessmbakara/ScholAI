import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/habits/domain/habit_models.dart';
import 'package:scholai_app/features/habits/presentation/cubit/habit_cubit.dart';
import 'package:scholai_app/features/habits/presentation/cubit/habit_state.dart';

/// Today: log urge intensity + outcome, streak summary, optional reflection.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  HabitKind? _habit;
  double _intensity = 3;
  UrgeOutcome _outcome = UrgeOutcome.rodeItOut;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<HabitCubit>();
      if (cubit.state.status == HabitStatus.initial) {
        cubit.load();
      }
    });
  }

  Future<void> _submitLog(HabitKind habit) async {
    final cubit = context.read<HabitCubit>();
    await cubit.logUrge(
      habit: habit,
      intensity: _intensity.round(),
      outcome: _outcome,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _outcome == UrgeOutcome.rodeItOut
              ? 'Logged — you rode that one out.'
              : 'Logged — noticing without judgment matters too.',
        ),
      ),
    );
  }

  Future<void> _reflect(HabitKind habit) async {
    await context.read<HabitCubit>().requestReflection(
          habit: habit,
          intensity: _intensity.round(),
          outcome: _outcome,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
        child: BlocConsumer<HabitCubit, HabitState>(
          listenWhen: (prev, next) =>
              prev.setupDone != next.setupDone ||
              (next.status == HabitStatus.ready &&
                  !next.setupDone &&
                  prev.status != HabitStatus.ready),
          listener: (context, state) {
            if (state.status == HabitStatus.ready && !state.setupDone) {
              context.go('/habits/setup');
            }
          },
          builder: (context, state) {
            if (state.status == HabitStatus.loading ||
                state.status == HabitStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!state.setupDone) {
              return const SizedBox.shrink();
            }

            final habits = state.selectedHabits;
            final HabitKind? activeHabit = (_habit != null && habits.contains(_habit))
                ? _habit
                : (habits.isEmpty ? null : habits.first);

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Urges',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit areas',
                      onPressed: () => context.push('/habits/setup?edit=1'),
                      icon: const Icon(Icons.tune_outlined),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Log the urge. Reflect if you want. No streaks of shame.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 14),
                _DisclaimerBanner(),
                const SizedBox(height: 20),
                _StatsRow(stats: state.stats),
                const SizedBox(height: 28),
                Text(
                  'Log an urge',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final h in habits)
                      ChoiceChip(
                        label: Text(h.label),
                        selected: activeHabit == h,
                        onSelected: (_) => setState(() => _habit = h),
                        selectedColor: AppColors.primary.withValues(alpha: 0.35),
                        backgroundColor: AppColors.surfaceCard,
                        labelStyle: TextStyle(
                          color: activeHabit == h
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: activeHabit == h
                              ? AppColors.primary
                              : AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Intensity · ${_intensity.round()}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surfaceCard,
                    thumbColor: AppColors.primaryLight,
                    overlayColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _intensity,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '${_intensity.round()}',
                    onChanged: (v) => setState(() => _intensity = v),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _OutcomeButton(
                        label: 'Rode it out',
                        selected: _outcome == UrgeOutcome.rodeItOut,
                        onTap: () =>
                            setState(() => _outcome = UrgeOutcome.rodeItOut),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OutcomeButton(
                        label: 'Acted on it',
                        selected: _outcome == UrgeOutcome.actedOn,
                        onTap: () =>
                            setState(() => _outcome = UrgeOutcome.actedOn),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: activeHabit == null
                      ? null
                      : () => _submitLog(activeHabit),
                  child: const Text('Save log'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: activeHabit == null || state.reflectionLoading
                      ? null
                      : () => _reflect(activeHabit),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: state.reflectionLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reflect on this urge'),
                ),
                if (state.reflectionPrompt != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reflection',
                          style: TextStyle(
                            color: AppColors.accentLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.reflectionPrompt!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            height: 1.45,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  'Recent',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                if (state.logs.isEmpty)
                  Text(
                    'No logs yet. When an urge shows up, catch it here.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  )
                else
                  ...state.logs.take(8).map((log) => _LogTile(log: log)),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.push('/crisis'),
                  child: const Text(
                    'Crisis support',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.25)),
      ),
      child: const Text(
        'Companion tool only — not medical or addiction treatment. '
        'If you feel unsafe, use crisis support.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final HabitStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Ridden out',
            value: '${stats.riddenOutTotal}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Day streak',
            value: '${stats.currentStreakDays}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Today',
            value: '${stats.todayLogCount}',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeButton extends StatelessWidget {
  const _OutcomeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.22)
          : AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textMuted.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final UrgeLog log;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('EEE · HH:mm').format(log.loggedAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.habit.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$time · intensity ${log.intensity}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              log.outcome.label,
              style: TextStyle(
                color: log.outcome == UrgeOutcome.rodeItOut
                    ? AppColors.accentLight
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
