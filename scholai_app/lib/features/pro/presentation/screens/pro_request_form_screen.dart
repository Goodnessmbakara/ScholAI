import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/checkin/presentation/widgets/category_chips.dart';
import 'package:scholai_app/features/pro/data/models/pro_request.dart';
import 'package:scholai_app/features/pro/data/pro_request_service.dart';

/// Request intake: topic, mode, time window, note, required anonymity consent.
class ProRequestFormScreen extends StatefulWidget {
  const ProRequestFormScreen({super.key});

  @override
  State<ProRequestFormScreen> createState() => _ProRequestFormScreenState();
}

class _ProRequestFormScreenState extends State<ProRequestFormScreen> {
  String? _topic;
  ProPreferredMode _mode = ProPreferredMode.chat;
  String _timeWindow = kProTimeWindows.last;
  final _noteController = TextEditingController();
  bool _consent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_topic == null || !_consent || _submitting) return;

    setState(() => _submitting = true);
    try {
      final request = await ProRequestService.instance.submitRequest(
        topic: _topic!,
        preferredMode: _mode,
        timeWindow: _timeWindow,
        note: _noteController.text,
        consentGiven: _consent,
      );
      if (!mounted) return;
      context.go('/pro-request/${request.id}');
    } on CrisisDivertException {
      if (!mounted) return;
      context.go('/crisis');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit request. Try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _topic != null && _consent && !_submitting;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Talk to a human'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            'Request a volunteer professional',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional peer or campus volunteer support — not clinical treatment '
            'or addiction therapy. Scholly stays available if you prefer AI.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 28),

          Text(
            'What’s on your mind?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          CategoryChips(
            categories: kProTopics,
            selected: _topic,
            onSelected: (t) => setState(() => _topic = t),
          ),
          const SizedBox(height: 28),

          Text(
            'Preferred mode',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  selected: _mode == ProPreferredMode.chat,
                  onTap: () => setState(() => _mode = ProPreferredMode.chat),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeCard(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  selected: _mode == ProPreferredMode.call,
                  onTap: () => setState(() => _mode = ProPreferredMode.call),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Text(
            'Preferred time window',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _timeWindow,
                isExpanded: true,
                dropdownColor: AppColors.surfaceCard,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                items: kProTimeWindows
                    .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _timeWindow = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Optional note',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 280,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Anything you’d like them to know before matching…',
              hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8)),
              filled: true,
              fillColor: AppColors.surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterStyle: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _consent,
                  activeColor: AppColors.primary,
                  checkColor: Colors.white,
                  side: const BorderSide(color: AppColors.textSecondary),
                  onChanged: (v) => setState(() => _consent = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'I understand this is not anonymous once requested. '
                      'Sharing my topic, contact preference, and note breaks '
                      'anonymity for this session so a volunteer can help me.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.45,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.surfaceCard,
                disabledForegroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit request'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push('/crisis'),
            child: const Text(
              'In crisis? Get help now',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primaryLight : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
