import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scholai_app/core/theme/app_theme.dart';

/// Crisis triage screen — shown when distress signals are detected.
class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key});

  static const _resources = [
    _CrisisResource(
      icon: '🏥',
      title: 'UI Counselling Centre',
      subtitle: 'Open Mon–Fri, 8am–4pm',
      detail: 'Career Development & Counselling Centre, University of Ibadan',
      action: 'Get directions',
      actionUrl: 'https://maps.google.com/?q=University+of+Ibadan+Counselling+Centre',
    ),
    _CrisisResource(
      icon: '📞',
      title: 'NSPI Crisis Line',
      subtitle: 'Nigeria Suicide Prevention Initiative',
      detail: '0800 800 2000 — Free, 24/7',
      action: 'Call now',
      actionUrl: 'tel:08008002000',
    ),
    _CrisisResource(
      icon: '💬',
      title: 'UI Mental Health Advocacy Group',
      subtitle: 'Student-led peer support',
      detail: '@uimhag on Instagram — student community',
      action: 'Find them',
      actionUrl: 'https://instagram.com/uimhag',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💛', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 12),
                    Text(
                      'It sounds like things are really heavy right now.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You don't have to go through this alone. These people are here to help — for real.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Reach out',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ..._resources.map((r) => _ResourceCard(resource: r)),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '← Go back',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final _CrisisResource resource;
  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(resource.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  resource.subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  resource.detail,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(resource.actionUrl)),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(resource.action, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _CrisisResource {
  final String icon, title, subtitle, detail, action, actionUrl;
  const _CrisisResource({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.action,
    required this.actionUrl,
  });
}
