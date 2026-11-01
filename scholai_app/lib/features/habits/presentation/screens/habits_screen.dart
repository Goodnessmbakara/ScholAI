import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:scholai_app/core/services/notification_service.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/habits/domain/habit_insights.dart';
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
  UrgeTrigger? _trigger;
  PornAct _pornAct = PornAct.porn;
  String _reasonDraft = '';
  HabitKind? _reasonHabit;
  final _noteCtrl = TextEditingController();
  final _speech = SpeechToText();
  bool _listening = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

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

  String _costDraft = '';

  void _captureReason(HabitKind habit, HabitPlan plan) {
    if (_reasonHabit == habit) return;
    _reasonHabit = habit;
    _reasonDraft = plan.reason;
    _costDraft = plan.dailyCost > 0 ? '${plan.dailyCost.round()}' : '';
  }

  Future<void> _openTimer(HabitKind habit, HabitPlan plan) async {
    final cubit = context.read<HabitCubit>();
    await cubit.savePlan(plan.copyWith(reason: _reasonDraft.trim()));
    if (!mounted) return;
    final message = await context.push<String>(
      '/habits/surf?habit=${habit.id}',
    );
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Speech recognition is not available here.')),
      );
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() => _noteCtrl.text = r.recognizedWords);
      },
      listenOptions:
          SpeechListenOptions(listenFor: const Duration(seconds: 30)),
    );
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _submitLog(HabitKind habit) async {
    final cubit = context.read<HabitCubit>();
    await cubit.logUrge(
      habit: habit,
      intensity: _intensity.round(),
      outcome: _outcome,
      trigger: _trigger,
      note: _noteCtrl.text,
      pornAct: _outcome == UrgeOutcome.actedOn && habit == HabitKind.pornUrges
          ? _pornAct
          : PornAct.none,
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
    if (_outcome == UrgeOutcome.actedOn) {
      _debriefAfterSlip(habit);
    }
  }

  /// Post-slip iteration: one gentle question that turns a slip into a plan.
  Future<void> _debriefAfterSlip(HabitKind habit) async {
    final ctrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text(
          'What do you want to try next time?',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. leave the room first, text Sam',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save it',
                style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
    if (note == null || note.isEmpty || !mounted) return;
    final cubit = context.read<HabitCubit>();
    await cubit.savePlan(
      cubit.state.planFor(habit).copyWith(nextTryNote: note),
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
            if (activeHabit == null) {
              return const SizedBox.shrink();
            }
            final plan = state.planFor(activeHabit);
            _captureReason(activeHabit, plan);
            final stats = computeHabitStats(
              logs: state.logs,
              habit: activeHabit,
              plan: plan,
              now: DateTime.now(),
            );
            final pattern = computeUrgePattern(state.logs, activeHabit);
            // Preemptive nudge — fires inside the usual window once the
            // pattern card knows it (no-ops until ready / when unchanged).
            unawaited(NotificationService.instance.syncUrgeWindowNudge(
              pattern.ready ? pattern.timeLabel : null,
              plan.displayName,
            ));

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
                  'Five minutes when it hits. Your best run stays either way.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 14),
                _DisclaimerBanner(),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final h in habits)
                      ChoiceChip(
                        label: Text(state.planFor(h).displayName),
                        selected: activeHabit == h,
                        onSelected: (selected) {
                          if (!selected || h == activeHabit) return;
                          if (_reasonDraft.trim() != plan.reason.trim()) {
                            context.read<HabitCubit>().savePlan(
                                  plan.copyWith(reason: _reasonDraft.trim()),
                                );
                          }
                          setState(() {
                            _habit = h;
                            _reasonHabit = null;
                          });
                        },
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
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _openTimer(activeHabit, plan),
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Urge is here · 5 min'),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    iconColor: AppColors.textSecondary,
                    collapsedIconColor: AppColors.textSecondary,
                    title: const Text(
                      'Plan & rules',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${plan.displayName} · ${plan.aim.label}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    children: [
                Row(
                  children: [
                    for (final aim in HabitAim.values) ...[
                      Expanded(
                        child: _OutcomeButton(
                          label: aim.label,
                          selected: plan.aim == aim,
                          onTap: () => context.read<HabitCubit>().savePlan(
                                plan.copyWith(aim: aim),
                              ),
                        ),
                      ),
                      if (aim != HabitAim.values.last) const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  plan.aim.hint,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (activeHabit == HabitKind.pornUrges) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'What counts as a slip?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _OutcomeButton(
                          label: 'Porn only',
                          selected: !plan.masturbationCountsAsSlip,
                          onTap: () => context.read<HabitCubit>().savePlan(
                                plan.copyWith(masturbationCountsAsSlip: false),
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OutcomeButton(
                          label: 'Porn + masturbation',
                          selected: plan.masturbationCountsAsSlip,
                          onTap: () => context.read<HabitCubit>().savePlan(
                                plan.copyWith(masturbationCountsAsSlip: true),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.masturbationCountsAsSlip
                        ? 'Both porn and masturbation end a Stop run.'
                        : 'Only porn ends a Stop run — masturbation alone is logged, not a slip.',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey(activeHabit),
                  initialValue: plan.reason,
                  maxLength: 140,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Reason this matters',
                    hintText: 'Shown during the five minutes',
                    counterText: '',
                  ),
                  onChanged: (value) => _reasonDraft = value,
                  onEditingComplete: () {
                    context.read<HabitCubit>().savePlan(
                          plan.copyWith(reason: _reasonDraft.trim()),
                        );
                    FocusScope.of(context).unfocus();
                  },
                ),
                if (plan.counterMove.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Counter-move · ${plan.counterMove}',
                    style: const TextStyle(
                        color: AppColors.accentLight, fontSize: 13, height: 1.4),
                  ),
                ],
                if (plan.nextTryNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Next time: ${plan.nextTryNote}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('cost_${activeHabit.id}'),
                  initialValue: plan.dailyCost > 0
                      ? '${plan.dailyCost.round()}'
                      : '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Daily cost (₦, optional)',
                    hintText: 'Shows "saved so far" on a Stop run',
                    counterText: '',
                  ),
                  onChanged: (v) => _costDraft = v,
                  onEditingComplete: () {
                    context.read<HabitCubit>().savePlan(
                          plan.copyWith(
                            dailyCost:
                                double.tryParse(_costDraft) ?? plan.dailyCost,
                          ),
                        );
                    FocusScope.of(context).unfocus();
                  },
                ),
                    ],
                  ),
                ),
                if (pattern.ready &&
                    pattern.topTrigger != null &&
                    plan.counterMove.isEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your urges usually land in the ${pattern.timeLabel} '
                          'after ${pattern.topTrigger!.patternPhrase}. '
                          'Pick your counter-move:',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              height: 1.4,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final move
                                in kCounterMoves[pattern.topTrigger!]!)
                              ActionChip(
                                label: Text(
                                  move,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12),
                                ),
                                backgroundColor: AppColors.surfaceMid,
                                onPressed: () => context
                                    .read<HabitCubit>()
                                    .savePlan(
                                      plan.copyWith(counterMove: move),
                                    ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Log it now',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
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
                if (_outcome == UrgeOutcome.actedOn &&
                    activeHabit == HabitKind.pornUrges) ...[
                  const SizedBox(height: 12),
                  _OutcomeButton(
                    label: 'Porn',
                    selected: _pornAct == PornAct.porn,
                    onTap: () => setState(() => _pornAct = PornAct.porn),
                  ),
                  const SizedBox(height: 8),
                  _OutcomeButton(
                    label: plan.masturbationCountsAsSlip
                        ? 'Masturbation without porn'
                        : 'Masturbation without porn — not a slip',
                    selected: _pornAct == PornAct.masturbationOnly,
                    onTap: () => setState(() => _pornAct = PornAct.masturbationOnly),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final trigger in UrgeTrigger.values)
                      ChoiceChip(
                        label: Text(trigger.label),
                        selected: _trigger == trigger,
                        onSelected: (_) => setState(() => _trigger = trigger),
                        selectedColor: AppColors.primary.withValues(alpha: 0.35),
                        backgroundColor: AppColors.surfaceCard,
                        labelStyle: TextStyle(
                          color: _trigger == trigger
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: _trigger == trigger
                              ? AppColors.primary
                              : AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _noteCtrl,
                  maxLength: 140,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'Or tap the mic and say it',
                    counterText: '',
                    suffixIcon: IconButton(
                      tooltip: _listening ? 'Stop listening' : 'Say it instead',
                      icon: Icon(
                        _listening ? Icons.mic : Icons.mic_none,
                        color: _listening
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      onPressed: _toggleListen,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _submitLog(activeHabit),
                  child: const Text('Save log'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: state.reflectionLoading
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
                _StatsRow(stats: stats),
                if (plan.dailyCost > 0 &&
                    stats.abstinenceStreak &&
                    stats.currentStreakDays > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '≈ ₦${(plan.dailyCost * stats.currentStreakDays).toStringAsFixed(0)} kept so far this run.',
                      style: const TextStyle(
                          color: AppColors.accentLight, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 16),
                _PatternCard(pattern: pattern),
                const SizedBox(height: 24),
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

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});

  final UrgePattern pattern;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PATTERN',
            style: TextStyle(
              color: AppColors.accentLight,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pattern.summary,
            style: const TextStyle(
              color: AppColors.textPrimary,
              height: 1.4,
              fontSize: 14,
            ),
          ),
        ],
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
            label: stats.abstinenceStreak ? 'This run' : 'Check-ins',
            value: '${stats.currentStreakDays}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Best',
            value: '${stats.bestStreakDays}',
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
                    '$time · intensity ${log.intensity}'
                    '${log.trigger == null ? '' : ' · ${log.trigger!.label}'}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              log.outcomeLabel,
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
