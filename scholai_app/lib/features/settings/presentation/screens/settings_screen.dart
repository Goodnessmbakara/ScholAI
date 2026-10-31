import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/core/services/encryption_service.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/account/data/account_service.dart';
import 'package:scholai_app/features/pro/data/models/pro_request.dart';
import 'package:scholai_app/features/pro/data/pro_request_service.dart';
import 'package:scholai_app/features/safety/domain/conversation_report.dart';
import 'package:scholai_app/features/safety/presentation/report_conversation_sheet.dart';

/// Optional account linking — anonymous by default; Google to sync across devices.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _privacyUrl =
      'https://project-4a50b4ec-612b-4d64-8b5.web.app/privacy';
  static const _deleteAccountUrl =
      'https://project-4a50b4ec-612b-4d64-8b5.web.app/delete-account';

  static const _avatarChoices = [
    '🌱', '🌿', '🌻', '🌙', '⭐', '🦋', '🍃', '💛', '🕊️', '🔥',
  ];

  bool _busy = false;
  bool _savingProfile = false;
  List<ProRequest> _recentRequests = const [];
  final _nameCtrl = TextEditingController();
  String _avatarEmoji = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _openExternal(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that page.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecentRequests();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AccountService.instance.ensureProfile();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = profile?.displayName ?? '';
      _avatarEmoji = profile?.avatarEmoji ?? '';
    });
  }

  Future<void> _saveProfile({String? avatarEmoji}) async {
    if (_savingProfile) return;
    setState(() => _savingProfile = true);
    try {
      await AccountService.instance.updateProfile(
        displayName: _nameCtrl.text,
        avatarEmoji: avatarEmoji ?? _avatarEmoji,
      );
      if (!mounted) return;
      setState(() {
        if (avatarEmoji != null) _avatarEmoji = avatarEmoji;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  void _pickAvatar() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pick your avatar',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final emoji in _avatarChoices)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _saveProfile(avatarEmoji: emoji);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _avatarEmoji == emoji
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _avatarEmoji == emoji
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmEraseLocal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceMid,
        title: const Text(
          'Erase data on this device?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Check-ins, habit plans, urge logs, the support-request mirror, and '
          'the on-device encryption key will be deleted. Your cloud account '
          'and support requests are not touched — use "Delete account" for that.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep my data'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Erase', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await EncryptionService.instance.cryptographicallyWipeData();
    if (!mounted) return;
    context.go('/onboarding');
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
      await AccountService.instance.ensureProfile();
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
      await AccountService.instance.ensureProfile();
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

          // Profile — display name + avatar, stored on the account and locally.
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
                Text(
                  'Your profile',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.25),
                        child: Text(
                          _avatarEmoji.isNotEmpty ? _avatarEmoji : '🌱',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 24,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          hintText: 'What should we call you?',
                          counterText: '',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap the avatar to change it. This is just for you — '
                  'it does not replace the name on your Google account.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        _savingProfile ? null : () => _saveProfile(),
                    child: _savingProfile
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save profile'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
            'Ask to speak with a professional, or apply to join the roster. '
            'Speaking with someone is not anonymous once you send the request.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => context.push('/support'),
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
                          'Support',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Talk with a professional, or apply to be one',
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
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryLight),
            title: const Text(
              'Privacy policy',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textMuted),
            onTap: () => _openExternal(_privacyUrl),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined, color: AppColors.primaryLight),
            title: const Text(
              'Report a conversation',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Scholly, live voice, or a professional',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            onTap: () => showReportConversationSheet(
              context,
              kind: ConversationKind.aiJournal,
              chooseKind: true,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline, color: AppColors.primaryLight),
            title: const Text(
              'Delete account',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Ask us to erase the cloud account',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textMuted),
            onTap: () => _openExternal(_deleteAccountUrl),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.primaryLight),
            title: const Text(
              'Erase data on this device',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Clears check-ins, habits, and the on-device key',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            onTap: _confirmEraseLocal,
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
