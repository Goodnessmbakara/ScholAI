import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholai_app/core/theme/scholai_colors.dart';
import 'package:scholai_app/shared/widgets/scholai_mark.dart';

/// 3-screen high-fidelity onboarding flow with editorial illustrations.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      imageAsset: 'assets/images/onboarding_welcome.jpg',
      badge: 'SAFE SANCTUARY',
      title: 'Welcome to your private reflection space',
      body: 'University life can be overwhelming. ScholAI gives you a calm, zero-judgment daily pause to check in with how you are genuinely doing.',
    ),
    _OnboardingPage(
      imageAsset: 'assets/images/onboarding_companion.jpg',
      badge: 'MEET SCHOLLY',
      title: 'A companion that asks, not prescribes',
      body: 'Scholly isn\'t a clinical therapist. It\'s a reflective guide asking one thoughtful question at a time to help you find your own inner clarity.',
    ),
    _OnboardingPage(
      imageAsset: 'assets/images/onboarding_privacy.jpg',
      badge: 'PRIVACY FIRST',
      title: 'Anonymous by default. Sync only if you choose.',
      body: 'No account required — you start anonymously. Optionally sign in with Google later to keep the same account across devices. Your university still cannot read your private reflections.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header with brand mark
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const ScholAIMark(size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'ScholAI',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _skipToHome,
                      child: Text(
                        'Skip',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),

            // Page View with editorial visuals
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _OnboardingPageView(page: _pages[i]),
              ),
            ),

            // Indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? colors.primary : colors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentPage < _pages.length - 1 ? 'Continue' : 'Enter Your Space →',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      await _skipToHome();
    }
  }

  Future<void> _skipToHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/home');
  }
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Visual asset with container styling & subtle warm border
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colors.textPrimary.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                page.imageAsset,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              page.badge,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: colors.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.55,
                ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String imageAsset;
  final String badge;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.imageAsset,
    required this.badge,
    required this.title,
    required this.body,
  });
}
