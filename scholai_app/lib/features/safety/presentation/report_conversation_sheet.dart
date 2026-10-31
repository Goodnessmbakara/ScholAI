import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/safety/data/conversation_report_service.dart';
import 'package:scholai_app/features/safety/domain/conversation_report.dart';

Future<void> showReportConversationSheet(
  BuildContext context, {
  required ConversationKind kind,
  bool chooseKind = false,
  String excerpt = '',
  String requestId = '',
  String counterpartName = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    builder: (context) => _ReportSheet(
      initialKind: kind,
      chooseKind: chooseKind,
      excerpt: excerpt,
      requestId: requestId,
      counterpartName: counterpartName,
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.initialKind,
    required this.chooseKind,
    required this.excerpt,
    required this.requestId,
    required this.counterpartName,
  });

  final ConversationKind initialKind;
  final bool chooseKind;
  final String excerpt;
  final String requestId;
  final String counterpartName;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _note = TextEditingController();
  late ConversationKind _kind;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _note.text.trim();
    if (note.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ConversationReportService.instance.submit(
        kind: _kind,
        note: note,
        excerpt: widget.excerpt,
        requestId: widget.requestId,
        counterpartName: widget.counterpartName,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report sent. A person on the ScholAI team will read it.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send the report. Try again in a moment.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report this conversation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say what felt wrong. A person on the team reads it. '
            'This is not a substitute for urgent help.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 16),
          if (widget.chooseKind)
            DropdownButtonFormField<ConversationKind>(
              initialValue: _kind,
              dropdownColor: AppColors.surfaceMid,
              decoration: const InputDecoration(labelText: 'Conversation'),
              items: [
                for (final kind in ConversationKind.values)
                  DropdownMenuItem(value: kind, child: Text(kind.label)),
              ],
              onChanged: _sending ? null : (kind) => setState(() => _kind = kind ?? _kind),
            )
          else
            Text(
              _kind.label,
              style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'What should we look at?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _sending ? null : _submit,
              child: Text(_sending ? 'Sending…' : 'Send report'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _sending
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      context.go('/crisis');
                    },
              child: const Text('If you are in danger, get help now'),
            ),
          ),
        ],
      ),
    );
  }
}
