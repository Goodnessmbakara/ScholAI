import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/pro/data/models/pro_request.dart';
import 'package:scholai_app/features/pro/data/pro_request_service.dart';

/// Optional account linking — anonymous by default; Google to sync across devices.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  List<ProRequest> _recentRequests = const [];

  @override
  void initState() {
    super.initState();
    _loadRecentRequests();
  }

  Future<void> _loadRecentRequests() async {
    try {
      final list = await ProRequestService.instance.listRequests();
      if (!mounted) return;
      setState(() => _recentRequests = list.take(3).toList());
    } catch (_) {}
  }

  Future<void> _linkGoogle() async {
    final auth = context.read<AuthService>();
    setState(() => _busy = true);
    try {
      final result = await auth.linkOrSignInWithGoogle();
      if (!mounted) return;
      final message = switch (result) {
        GoogleLinkResult.cancelled => 'Sign-in cancelled.',
        GoogleLinkResult.linked =>
          'Google linked. Your anonymous data stays on this account across devices.',
        GoogleLinkResult.signedIn || GoogleLinkResult.signedInExisting =>
          'Signed in with Google. Cloud data for this account will sync here.',
        GoogleLinkResult.alreadyLinked => 'Google is already linked.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not sign in with Google. Check network and Firebase Google provider settings.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOutGoogle() async {
    final auth = context.read<AuthService>();
    setState(() => _busy = true);
    try {
      await auth.signOutToAnonymous();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed out of Google. Continuing as anonymous on this device.'),
        ),
      );
      setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final linked = auth.isGoogleLinked;
    final email = auth.linkedEmail;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Privacy first',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'ScholAI works anonymously by default — no Google account required. '
            'Optionally sign in with Google to keep the same account (and synced data) '
            'across multiple devices.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      linked ? Icons.verified_user_outlined : Icons.shield_outlined,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        linked ? 'Google linked' : 'Anonymous session',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  linked
                      ? (email ?? 'Signed in with Google')
                      : 'Device-local UID. Sign in optionally to persist across devices.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (auth.uid != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'UID · ${auth.uid!.substring(0, 8)}…',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_busy)
                  const Center(child: CircularProgressIndicator())
                else if (!linked)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _linkGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text('Continue with Google'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _signOutGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Sign out of Google'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Linking keeps your Firebase user ID so cloud data under /users/{uid} '
            'can follow you. Journals sent to Gemini are still processed by Google AI '
            'under their API terms.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 28),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.self_improvement_outlined, color: AppColors.primaryLight),
            title: const Text(
              'Urge areas',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Edit what you track in Habits',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.push('/habits/setup?edit=1'),
          ),
          const SizedBox(height: 28),
          Text(
            'Human support',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optionally request a volunteer professional. This breaks anonymity '
            'for that session once you consent and submit.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => context.push('/pro-request'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.volunteer_activism_outlined, color: AppColors.primaryLight),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Talk to a human',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Request chat or call with a volunteer',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_recentRequests.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Recent requests',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            ..._recentRequests.map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  r.topic,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
                subtitle: Text(
                  r.status.label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () => context.push('/pro-request/${r.id}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
