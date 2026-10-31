import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/account/data/account_service.dart';
import 'package:scholai_app/features/account/domain/platform_role.dart';

/// Two doors: ask for a professional, or ask to become one.
class SupportHubScreen extends StatefulWidget {
  const SupportHubScreen({super.key});

  @override
  State<SupportHubScreen> createState() => _SupportHubScreenState();
}

class _SupportHubScreenState extends State<SupportHubScreen> {
  PlatformProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await AccountService.instance.ensureProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            'People, when you want them',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask to speak with a professional, or apply to be one. '
            'A super admin reviews applications before anyone is listed.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 24),
          _Door(
            icon: Icons.forum_outlined,
            title: 'Speak with a professional',
            subtitle: 'Request a chat or a call. This is not anonymous once you send it.',
            onTap: () => context.push('/pro-request'),
          ),
          const SizedBox(height: 12),
          _Door(
            icon: Icons.badge_outlined,
            title: 'Apply to be a professional',
            subtitle: 'Counsellors, trainees, and peer supporters can ask to join.',
            onTap: () => context.push('/pro-apply'),
          ),
          if (profile?.role == PlatformRole.professional) ...[
            const SizedBox(height: 12),
            _Door(
              icon: Icons.forum_rounded,
              title: 'My support cases',
              subtitle: 'Students matched to you — reply in their thread.',
              onTap: () => context.push('/my-cases'),
            ),
          ],
          if (profile?.canManagePlatform == true) ...[
            const SizedBox(height: 12),
            _Door(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Platform admin',
              subtitle: profile!.canAssignRoles
                  ? 'Review people, the queue, and every role.'
                  : 'Review applications and the support queue.',
              onTap: () => context.push('/admin'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Door extends StatelessWidget {
  const _Door({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
