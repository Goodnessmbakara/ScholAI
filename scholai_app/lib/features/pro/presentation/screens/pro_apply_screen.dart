import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/account/data/account_service.dart';
import 'package:scholai_app/features/pro/data/models/pro_application.dart';
import 'package:scholai_app/features/pro/data/pro_application_service.dart';

class ProApplyScreen extends StatefulWidget {
  const ProApplyScreen({super.key});

  @override
  State<ProApplyScreen> createState() => _ProApplyScreenState();
}

class _ProApplyScreenState extends State<ProApplyScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _organization = TextEditingController();
  final _bio = TextEditingController();
  String _credential = kProCredentials.first;
  final _areas = <String>{};
  bool _loading = true;
  bool _saving = false;
  bool _google = false;
  ProApplication? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _organization.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await AccountService.instance.ensureProfile();
    final linked = AuthService.instance.isGoogleLinked;
    ProApplication? existing;
    if (linked) {
      try {
        existing = await ProApplicationService.instance.mine();
      } catch (_) {}
    }
    if (!mounted) return;
    if (existing != null && existing.status != ProApplicationStatus.approved) {
      _name.text = existing.name;
      _phone.text = existing.phone;
      _organization.text = existing.organization;
      _bio.text = existing.bio;
      _credential = kProCredentials.contains(existing.credential)
          ? existing.credential
          : kProCredentials.last;
      _areas
        ..clear()
        ..addAll(existing.areas);
    }
    setState(() {
      _google = linked;
      _existing = existing;
      _loading = false;
    });
  }

  Future<void> _linkGoogle() async {
    setState(() => _saving = true);
    try {
      final result = await AuthService.instance.linkOrSignInWithGoogle();
      if (result == GoogleLinkResult.cancelled) return;
      await AccountService.instance.ensureProfile();
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in did not finish.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    final uid = AuthService.instance.uid;
    final email = AuthService.instance.linkedEmail ?? '';
    if (uid == null || email.isEmpty) return;
    if (_name.text.trim().length < 2 ||
        _organization.text.trim().isEmpty ||
        _bio.text.trim().length < 20 ||
        _areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add your name, campus or clinic, a short bio, and one area.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ProApplicationService.instance.submit(
        ProApplication(
          uid: uid,
          name: _name.text.trim(),
          email: email,
          phone: _phone.text.trim(),
          credential: _credential,
          organization: _organization.text.trim(),
          bio: _bio.text.trim(),
          areas: _areas.toList(),
          status: ProApplicationStatus.pending,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application sent. A super admin will review it.')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send the application. Check your connection and rules.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Be a professional'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Text(
                  'Join the roster',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Students can ask to talk with you after a super admin approves this. '
                  'ScholAI is a companion, not a clinic. If someone is in crisis, they are sent to crisis support.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 20),
                if (!_google) ...[
                  const Text(
                    'Use Google so we know who is applying. Anonymous sessions cannot join the roster.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _linkGoogle,
                    child: const Text('Continue with Google'),
                  ),
                ] else if (_existing?.status == ProApplicationStatus.approved) ...[
                  const Text(
                    'You are approved. Students can be matched with you.',
                    style: TextStyle(color: AppColors.accentLight, height: 1.4),
                  ),
                ] else ...[
                  if (_existing != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _existing!.status == ProApplicationStatus.rejected
                            ? 'The last application was not approved. You can send another.'
                            : 'Your application is waiting for review. Sending again updates it.',
                        style: const TextStyle(color: AppColors.warning, height: 1.4),
                      ),
                    ),
                  Text(
                    AuthService.instance.linkedEmail ?? '',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _field(_name, 'Full name'),
                  const SizedBox(height: 12),
                  _field(_phone, 'Phone', keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(_organization, 'Campus, clinic, or group'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _credential,
                    dropdownColor: AppColors.surfaceCard,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'What you do'),
                    items: [
                      for (final item in kProCredentials)
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _credential = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Areas you can sit with',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final area in kProSupportAreas)
                        FilterChip(
                          label: Text(area),
                          selected: _areas.contains(area),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _areas.add(area);
                              } else {
                                _areas.remove(area);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.35),
                          backgroundColor: AppColors.surfaceCard,
                          labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          side: BorderSide(
                            color: _areas.contains(area)
                                ? AppColors.primary
                                : AppColors.textMuted.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(_bio, 'Short bio', lines: 4),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: Text(_saving ? 'Sending…' : 'Submit application'),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      keyboardType: keyboard,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label),
    );
  }
}
