import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scholai_app/core/services/gemini_service.dart';
import 'package:scholai_app/core/theme/scholai_colors.dart';
import 'package:scholai_app/features/checkin/data/checkin_local_store.dart';

/// Mood trend chart — shows pattern over last 7 days with seedling visual.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  static const _windowDays = 7;

  List<CheckInEntry>? _entries;
  String? _aiInsight;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await CheckInLocalStore.instance.loadLastDays(_windowDays);
    if (!mounted) return;
    setState(() => _entries = entries);
    _loadAiInsight(entries);
  }

  /// Personalized Gemini insight — replaces the static line only when a
  /// real reply comes back; the static text stays the fallback.
  Future<void> _loadAiInsight(List<CheckInEntry> entries) async {
    if (entries.isEmpty || !GeminiService.instance.hasApiKey) return;
    try {
      final week = [
        for (final e in entries)
          (
            mood: e.mood,
            day: DateFormat.E().format(e.day),
            category: e.category ?? '',
          ),
      ];
      final text = await GeminiService.instance
          .generateTrendInsight(week)
          .timeout(const Duration(seconds: 12));
      if (!mounted || text == null || text.isEmpty) return;
      setState(() => _aiInsight = text);
    } catch (_) {
      // Static insight stays.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = _entries;

    final today = CheckInEntry.dayOnly(DateTime.now());
    final days = List.generate(
      _windowDays,
      (i) => today.subtract(Duration(days: _windowDays - 1 - i)),
    );
    final byDay = {
      for (final e in entries ?? const <CheckInEntry>[]) e.day: e,
    };
    final loggedDays = days.where(byDay.containsKey).toList();

    String insight;
    if (entries == null) {
      insight = '';
    } else if (loggedDays.isEmpty) {
      insight = 'No check-ins this week yet. Your first one starts the pattern.';
    } else {
      final lowestDay = loggedDays.reduce(
        (a, b) => byDay[a]!.mood <= byDay[b]!.mood ? a : b,
      );
      final lowest = DateFormat.E().format(lowestDay);
      insight = 'Your lowest day was $lowest. You\'ve been here before — '
          'and you persevered through it.';
    }
    if (_aiInsight != null && _aiInsight!.isNotEmpty) {
      insight = _aiInsight!;
    }

    return Scaffold(
      backgroundColor: colors.surfaceDark,
      appBar: AppBar(
        title: const Text('Weekly Reflection'),
        backgroundColor: colors.surfaceDark,
      ),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: colors.primaryLight,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                                  insight,
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
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Bar chart container
                    Container(
                      height: 220,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: colors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          for (final day in days)
                            _DayBar(
                              day: day,
                              entry: byDay[day],
                              colors: colors,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.day,
    required this.entry,
    required this.colors,
  });

  final DateTime day;
  final CheckInEntry? entry;
  final ScholAIColors colors;

  @override
  Widget build(BuildContext context) {
    final mood = entry?.mood;
    final color = mood == null ? null : _moodColor(mood, colors);
    final isToday = day == CheckInEntry.dayOnly(DateTime.now());

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          width: 32,
          height: mood != null ? mood * 28.0 : 12.0,
          decoration: BoxDecoration(
            color: color ?? colors.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: color == null
                ? Border.all(
                    color: colors.textMuted.withValues(alpha: 0.35),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              if (color != null)
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
          DateFormat.E().format(day).substring(0, 3),
          style: TextStyle(
            color: isToday ? colors.primaryLight : colors.textMuted,
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
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
