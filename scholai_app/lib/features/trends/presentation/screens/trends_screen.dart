import 'package:flutter/material.dart';
import 'package:scholai_app/core/theme/app_theme.dart';

/// Mood trend chart — shows pattern over last 7 days.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  // Placeholder data — replace with Firestore stream
  final _mockData = [3, 2, 4, 2, 3, 5, 4];
  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final lowest = _days[_mockData.indexOf(_mockData.reduce((a, b) => a < b ? a : b))];

    return Scaffold(
      appBar: AppBar(title: const Text('Your Week')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Insight card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 This week', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Your lowest day was $lowest. You\'ve been here before — and you made it through.',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Placeholder bar chart
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_mockData.length, (i) {
                  final val = _mockData[i];
                  final color = _moodColor(val);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        width: 36,
                        height: val * 40.0,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_days[i], style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _moodColor(int mood) {
    return switch (mood) {
      1 => AppColors.moodVeryLow,
      2 => AppColors.moodLow,
      3 => AppColors.moodNeutral,
      4 => AppColors.moodGood,
      _ => AppColors.moodGreat,
    };
  }
}
