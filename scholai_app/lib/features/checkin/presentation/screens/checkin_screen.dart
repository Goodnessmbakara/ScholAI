import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/account/data/account_service.dart';
import 'package:scholai_app/features/checkin/data/checkin_local_store.dart';
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
  bool _ready = false;
  String _profileName = '';
  bool _showHumanNudge = false;

  /// Every 14 days, ask whether the student has talked to a real person —
  /// PRD §9 guardrail against relying on the app instead of humans.
  static const _nudgeKey = 'last_human_nudge';

  final List<String> _categories = [
    '📚 Exams', '💸 Money', '🏠 Family', '❤️ Relationships', '😴 Sleep', '🌀 Just overwhelmed',
  ];

  @override
  void initState() {
    super.initState();
    _restoreToday();
  }

  Future<void> _restoreToday() async {
    final draft = await CheckInLocalStore.instance.loadToday();
    final profile = AccountService.instance.profile ??
        await AccountService.instance.ensureProfile();
    final prefs = await SharedPreferences.getInstance();
    final lastNudge =
        DateTime.tryParse(prefs.getString(_nudgeKey) ?? '');
    if (!mounted) return;
    setState(() {
      _showHumanNudge = lastNudge == null ||
          DateTime.now().difference(lastNudge).inDays >= 14;
      if (draft != null) {
        _selectedMood = draft.mood;
        _selectedCategory =
            _categories.contains(draft.category) ? draft.category : null;
      }
      _profileName = (profile?.displayName ?? '').trim();
      _ready = true;
    });
  }

  Future<void> _dismissNudge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nudgeKey, DateTime.now().toIso8601String());
    if (mounted) setState(() => _showHumanNudge = false);
  }

  Future<void> _remember() async {
    final mood = _selectedMood;
    if (mood == null) return;
    await CheckInLocalStore.instance.saveToday(
      mood: mood,
      category: _selectedCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'How far';

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profileName.isEmpty
                              ? '$greeting 👋'
                              : '$greeting, $_profileName 👋',
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
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Account',
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_showHumanNudge)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Have you spoken to anyone in person recently? '
                          'A chat with a friend counts too.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Got it',
                        icon: const Icon(Icons.close,
                            color: AppColors.textMuted, size: 18),
                        onPressed: _dismissNudge,
                      ),
                    ],
                  ),
                ),

              // Gemini Live Sanctuary Banner
              InkWell(
                onTap: () => context.push('/live'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        AppColors.surfaceCard,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.graphic_eq, color: AppColors.primaryLight, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gemini Live Audio Sanctuary',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Talk out loud to Scholly in real time',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_ready)
                        const SizedBox(
                          height: 80,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        MoodSelector(
                          onMoodSelected: (mood) {
                            setState(() => _selectedMood = mood);
                            _remember();
                          },
                          selectedMood: _selectedMood,
                        ),
                      if (_selectedMood != null) ...[
                        const SizedBox(height: 32),
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
                          onSelected: (cat) {
                            setState(() => _selectedCategory = cat);
                            _remember();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_selectedMood != null) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _onSave,
                  child: const Text('Save check-in'),
                ),
                TextButton(
                  onPressed: () => context.go('/journal'),
                  child: const Text(
                    'Want to talk about it?',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/support'),
                  child: const Text(
                    'Talk to someone',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    final mood = _selectedMood;
    if (mood == null) return;
    await _remember();
    await CheckInLocalStore.instance.recordEntry(
      mood: mood,
      category: _selectedCategory,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Logged! Have a good one.')),
    );

    // Crisis triage: two lowest moods for 3+ consecutive days surfaces
    // the resource screen (pushed, so the student can come back).
    final recent = await CheckInLocalStore.instance.loadLastDays(3);
    if (mounted &&
        recent.length == 3 &&
        recent.every((e) => e.mood <= 2)) {
      context.push('/crisis');
    }
  }
}
