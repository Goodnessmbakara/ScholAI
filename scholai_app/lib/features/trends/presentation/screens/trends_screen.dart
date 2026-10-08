import 'package:flutter/material.dart';
import 'package:scholai_app/core/theme/scholai_colors.dart';

/// Mood trend chart — shows pattern over last 7 days with seedling visual.
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
    final colors = context.colors;
    final lowest = _days[_mockData.indexOf(_mockData.reduce((a, b) => a < b ? a : b))];

    return Scaffold(
      backgroundColor: colors.surfaceDark,
      appBar: AppBar(
        title: const Text('Weekly Reflection'),
        backgroundColor: colors.surfaceDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Insight Card with Seedling visual anchor
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.textPrimary.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/trends_empty_seedling.jpg',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🌱 GENTLE PROGRESS',
                          style: TextStyle(
                            color: colors.primaryLight,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your lowest day was $lowest. You\'ve been here before — and you persevered through it.',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Daily Emotional Rhythm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Patterns from your 60-second morning & evening check-ins',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Bar chart container
            Container(
              height: 220,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_mockData.length, (i) {
                  final val = _mockData[i];
                  final color = _moodColor(val, colors);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        width: 32,
                        height: val * 28.0,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _days[i],
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _moodColor(int mood, ScholAIColors colors) {
    return switch (mood) {
      1 => colors.moodVeryLow,
      2 => colors.moodLow,
      3 => colors.moodNeutral,
      4 => colors.moodGood,
      _ => colors.moodGreat,
    };
  }
}
