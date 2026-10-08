import 'package:flutter/material.dart';
import 'package:scholai_app/core/theme/app_theme.dart';

/// 5-point mood selector using emoji + colour gradient.
class MoodSelector extends StatelessWidget {
  final int? selectedMood;
  final ValueChanged<int> onMoodSelected;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  static const _moods = [
    (emoji: '😞', label: 'Rough',   color: AppColors.moodVeryLow),
    (emoji: '😕', label: 'Low',     color: AppColors.moodLow),
    (emoji: '😐', label: 'Okay',    color: AppColors.moodNeutral),
    (emoji: '🙂', label: 'Good',    color: AppColors.moodGood),
    (emoji: '😊', label: 'Great',   color: AppColors.moodGreat),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_moods.length, (i) {
        final mood = _moods[i];
        final isSelected = selectedMood == i + 1;

        return GestureDetector(
          onTap: () => onMoodSelected(i + 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: isSelected ? 64 : 56,
            height: isSelected ? 80 : 72,
            decoration: BoxDecoration(
              color: isSelected
                  ? mood.color.withValues(alpha: 0.25)
                  : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? mood.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mood.emoji, style: TextStyle(fontSize: isSelected ? 30 : 26)),
                const SizedBox(height: 4),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? mood.color : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
