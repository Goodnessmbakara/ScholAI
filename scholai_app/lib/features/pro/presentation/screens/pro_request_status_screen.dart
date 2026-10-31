import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/pro/data/models/pro_request.dart';
import 'package:scholai_app/features/pro/data/pro_request_service.dart';

/// Shows request lifecycle and actions (chat / call / cancel).
class ProRequestStatusScreen extends StatefulWidget {
  final String requestId;

  const ProRequestStatusScreen({super.key, required this.requestId});

  @override
  State<ProRequestStatusScreen> createState() => _ProRequestStatusScreenState();
}

class _ProRequestStatusScreenState extends State<ProRequestStatusScreen> {
  ProRequest? _request;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  StreamSubscription<ProRequest?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ProRequestService.instance
        .watchRequest(widget.requestId)
        .listen(
          _onRequest,
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = 'Could not load request.';
            });
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onRequest(ProRequest? req) {
    if (!mounted) return;
    setState(() {
      _request = req;
      _loading = false;
      _error = req == null ? 'Request not found.' : null;
    });
  }

  /// One-shot refresh for the app-bar button — the stream already keeps this
  /// screen live, but this re-reads the local copy when offline.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final req = await ProRequestService.instance.getRequest(widget.requestId);
      if (!mounted) return;
      setState(() {
        _request = req;
        _loading = false;
        if (req == null) _error = 'Request not found.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load request.';
      });
    }
  }

  Future<void> _openChat() async {
    final req = _request;
    if (req == null) return;
    setState(() => _busy = true);
    try {
      if (req.status == ProRequestStatus.matched ||
          req.status == ProRequestStatus.pending) {
        await ProRequestService.instance.scheduleChat(req.id);
      }
      if (!mounted) return;
      context.push('/pro-request/${req.id}/chat');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestCall() async {
    final req = _request;
    if (req == null) return;
    setState(() => _busy = true);
    try {
      final updated = await ProRequestService.instance.requestCall(req.id);
      if (!mounted) return;
      setState(() => _request = updated);

      final phone = updated.professionalPhone;
      if (phone != null && phone.isNotEmpty) {
        final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Call scheduled for ${updated.timeWindow}. Volunteer will call back.',
              ),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Callback scheduled for ${updated.timeWindow}. '
              '${updated.professionalName ?? 'Your volunteer'} will reach out.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final req = _request;
    if (req == null) return;
    setState(() => _busy = true);
    try {
      final updated = await ProRequestService.instance.cancel(req.id);
      if (!mounted) return;
      setState(() => _request = updated);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color _statusColor(ProRequestStatus status) => switch (status) {
        ProRequestStatus.pending => AppColors.warning,
        ProRequestStatus.matched => AppColors.accentLight,
        ProRequestStatus.chatScheduled ||
        ProRequestStatus.callScheduled =>
          AppColors.primaryLight,
        ProRequestStatus.completed => AppColors.success,
        ProRequestStatus.cancelled => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Request status'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/pro-request'),
                          child: const Text('New request'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildBody(_request!),
    );
  }

  Widget _buildBody(ProRequest req) {
    final active = req.status != ProRequestStatus.cancelled &&
        req.status != ProRequestStatus.completed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(req.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      req.status.label,
                      style: TextStyle(
                        color: _statusColor(req.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    req.preferredMode.label,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                req.topic,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Window · ${req.timeWindow}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              if (req.note != null && req.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  req.note!,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'This session is not anonymous. Your topic and contact preference '
            'are shared with the matched volunteer.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ),
        const SizedBox(height: 20),

        if (req.professionalName != null) ...[
          Text(
            'Matched volunteer',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                  child: Text(
                    req.professionalName!.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.primaryLight),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.professionalName!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (req.professionalRole != null)
                        Text(
                          req.professionalRole!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ] else if (req.status == ProRequestStatus.pending) ...[
          const Text(
            'Looking for a volunteer…',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
        ],

        if (_busy)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ))
        else if (active) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open chat'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _requestCall,
              icon: const Icon(Icons.call_outlined),
              label: const Text('Request call'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _cancel,
            child: const Text(
              'Cancel request',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: () => context.go('/pro-request'),
            child: const Text(
              'Start a new request',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }
}
