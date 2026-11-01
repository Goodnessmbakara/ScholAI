import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/habits/domain/habit_models.dart';
import 'package:scholai_app/features/habits/presentation/cubit/habit_cubit.dart';

/// Five-minute wall-clock timer for the moment an urge hits.
class UrgeTimerScreen extends StatefulWidget {
  const UrgeTimerScreen({super.key, required this.habit});

  final HabitKind habit;

  @override
  State<UrgeTimerScreen> createState() => _UrgeTimerScreenState();
}

class _UrgeTimerScreenState extends State<UrgeTimerScreen> {
  static const _length = Duration(minutes: 5);

  late final DateTime _endsAt;
  Timer? _ticker;
  Duration _left = _length;
  bool _finished = false;
  UrgeOutcome? _outcome;
  PornAct _pornAct = PornAct.porn;
  UrgeTrigger? _trigger;
  double _intensity = 3;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _endsAt = DateTime.now().add(_length);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    final left = _endsAt.difference(DateTime.now());
    if (!mounted) return;
    if (left <= Duration.zero) {
      _ticker?.cancel();
      setState(() {
        _left = Duration.zero;
        _finished = true;
      });
      return;
    }
    setState(() => _left = left);
  }

  void _finishEarly() {
    _ticker?.cancel();
    setState(() {
      _left = Duration.zero;
      _finished = true;
    });
  }

  Future<void> _save() async {
    final outcome = _outcome;
    if (outcome == null || _saving) return;
    setState(() => _saving = true);
    await context.read<HabitCubit>().logUrge(
          habit: widget.habit,
          intensity: _intensity.round(),
          outcome: outcome,
          trigger: _trigger,
          pornAct: outcome == UrgeOutcome.actedOn &&
                  widget.habit == HabitKind.pornUrges
              ? _pornAct
              : PornAct.none,
        );
    if (!mounted) return;
    final message = outcome == UrgeOutcome.rodeItOut
        ? 'Logged — you rode that one out.'
        : 'Logged. This run can reset. Your best one stays.';
    context.pop(message);
  }

  /// Urge-surf script keyed to where you are in the five minutes.
  String _promptFor(Duration left) {
    final s = left.inSeconds;
    if (s > 240) return 'Notice where the urge sits in your body.';
    if (s > 120) return "It's rising — that's what urges do. They peak, then fade.";
    if (s > 60) return 'The peak is passing. Stay with it.';
    return 'Almost through — this part is the win.';
  }

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<HabitCubit>().state.planFor(widget.habit);
    final reason = plan.reason.trim();
    final breathingIn = DateTime.now().second % 8 < 4;
    final minutes = _left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _left.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(plan.displayName),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            if (!_finished) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _promptFor(_left),
                  key: ValueKey(_promptFor(_left)),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  breathingIn ? 'Breathe in' : 'Breathe out',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (plan.counterMove.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'Try instead: ${plan.counterMove}',
                    style: const TextStyle(
                      color: AppColors.accentLight,
                      height: 1.45,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (plan.nextTryNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Last time you said: ${plan.nextTryNote}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (reason.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    reason,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.45,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                Text(
                  'Add a reason on the Urges screen and it will sit here next time.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: _finishEarly,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.45)),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('I’m ready to log it'),
              ),
            ] else ...[
              Text(
                'How did it go?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                plan.aim.hint,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Choice(
                      label: 'Rode it out',
                      selected: _outcome == UrgeOutcome.rodeItOut,
                      onTap: () => setState(() => _outcome = UrgeOutcome.rodeItOut),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Choice(
                      label: 'Acted on it',
                      selected: _outcome == UrgeOutcome.actedOn,
                      onTap: () => setState(() => _outcome = UrgeOutcome.actedOn),
                    ),
                  ),
                ],
              ),
              if (_outcome == UrgeOutcome.actedOn &&
                  widget.habit == HabitKind.pornUrges) ...[
                const SizedBox(height: 18),
                const Text(
                  'What happened?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _Choice(
                  label: 'Porn',
                  selected: _pornAct == PornAct.porn,
                  onTap: () => setState(() => _pornAct = PornAct.porn),
                ),
                const SizedBox(height: 8),
                _Choice(
                  label: plan.masturbationCountsAsSlip
                      ? 'Masturbation without porn'
                      : 'Masturbation without porn — not a slip',
                  selected: _pornAct == PornAct.masturbationOnly,
                  onTap: () => setState(() => _pornAct = PornAct.masturbationOnly),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Intensity · ${_intensity.round()}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: _intensity,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: AppColors.primary,
                onChanged: (value) => setState(() => _intensity = value),
              ),
              const SizedBox(height: 8),
              const Text(
                'What showed up first?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _outcome == null || _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save log'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
            textAlign: TextAlign.center,
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
