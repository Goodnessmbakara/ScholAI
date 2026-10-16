import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/habits/domain/habit_models.dart';
import 'package:scholai_app/features/habits/presentation/cubit/habit_cubit.dart';
import 'package:scholai_app/features/habits/presentation/cubit/habit_state.dart';

/// Multi-select onboarding for urge areas. Crisis / self-harm routes to `/crisis`.
class HabitPickerScreen extends StatefulWidget {
  const HabitPickerScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  State<HabitPickerScreen> createState() => _HabitPickerScreenState();
}

class _HabitPickerScreenState extends State<HabitPickerScreen> {
  late Set<HabitKind> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...context.read<HabitCubit>().state.selectedHabits};
  }

  IconData _iconFor(HabitKind kind) => switch (kind) {
        HabitKind.smoking => Icons.smoking_rooms,
        HabitKind.pornUrges => Icons.visibility_off_outlined,
        HabitKind.doomscrolling => Icons.phone_android_outlined,
      };

  Future<void> _continue() async {
    if (_selected.isEmpty) return;
    await context.read<HabitCubit>().saveSelectedHabits(_selected);
    if (!mounted) return;
    if (widget.fromSettings) {
      context.pop();
    } else {
      context.go('/habits');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Urge areas'),
        leading: widget.fromSettings
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              )
            : null,
        automaticallyImplyLeading: widget.fromSettings,
      ),
      body: SafeArea(
        child: BlocBuilder<HabitCubit, HabitState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What do you want gentle support tracking?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is urge logging and reflection — not clinical treatment '
                    'or an addiction program.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final kind in HabitKind.values) ...[
                          _HabitChoiceTile(
                            kind: kind,
                            icon: _iconFor(kind),
                            selected: _selected.contains(kind),
                            onTap: () {
                              setState(() {
                                if (_selected.contains(kind)) {
                                  _selected.remove(kind);
                                } else {
                                  _selected.add(kind);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/crisis'),
                          child: const Text(
                            'Having self-harm or crisis thoughts? Get support →',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _selected.isEmpty ? null : _continue,
                    child: Text(
                      widget.fromSettings ? 'Save' : 'Continue',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HabitChoiceTile extends StatelessWidget {
  const _HabitChoiceTile({
    required this.kind,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final HabitKind kind;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.18)
          : AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : AppColors.textMuted.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryLight),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kind.shortHint,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
