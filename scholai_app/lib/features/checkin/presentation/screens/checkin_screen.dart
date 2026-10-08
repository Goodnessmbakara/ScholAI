import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/checkin/presentation/widgets/mood_selector.dart';
import 'package:scholai_app/features/checkin/presentation/widgets/category_chips.dart';

/// The daily check-in screen — the heart of ScholAI.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  int? _selectedMood;
  String? _selectedCategory;

  final List<String> _categories = [
    '📚 Exams', '💸 Money', '🏠 Family', '❤️ Relationships', '😴 Sleep', '🌀 Just overwhelmed',
  ];

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'How far';

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                '$greeting 👋',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'How are you today?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 32),

              // Mood selector (5 emoji buttons)
              MoodSelector(
                onMoodSelected: (mood) => setState(() => _selectedMood = mood),
                selectedMood: _selectedMood,
              ),
              const SizedBox(height: 32),

              if (_selectedMood != null) ...[
                Text(
                  "What's most on your mind?",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                CategoryChips(
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                ),
                const SizedBox(height: 32),
              ],

              const Spacer(),

              // CTA
              if (_selectedMood != null)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _onSave,
                      child: const Text('Save check-in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/journal'),
                      child: const Text(
                        'Want to talk about it?',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (_selectedMood == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Logged! Have a good one.')),
    );
  }
}
