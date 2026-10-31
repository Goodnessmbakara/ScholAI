import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/journal/presentation/widgets/chat_bubble.dart';
import 'package:scholai_app/features/pro/data/models/pro_request.dart';
import 'package:scholai_app/features/pro/data/pro_request_service.dart';
import 'package:scholai_app/shared/models/chat_message.dart';

/// Staff-side view of a student request thread. Replies land on the
/// student's request doc as non-user messages, so they appear in the
/// student's chat as coming from their volunteer.
class StaffChatScreen extends StatefulWidget {
  final String userId;
  final String requestId;

  const StaffChatScreen({
    super.key,
    required this.userId,
    required this.requestId,
  });

  @override
  State<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends State<StaffChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  ProRequest? _request;
  bool _loading = true;
  bool _sending = false;
  StreamSubscription<ProRequest?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ProRequestService.instance
        .watchRequest(widget.requestId, forUid: widget.userId)
        .listen(_onRequest);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onRequest(ProRequest? req) {
    if (!mounted) return;
    final hadMessages = _request?.messages.length ?? 0;
    setState(() {
      _request = req;
      _loading = false;
    });
    if ((req?.messages.length ?? 0) != hadMessages) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _request == null) return;

    setState(() => _sending = true);
    _controller.clear();
    try {
      await ProRequestService.instance.appendStaffMessage(
        userId: widget.userId,
        requestId: widget.requestId,
        text: text,
      );
      _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send that reply. Admins only.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = _request;
    final active = req != null &&
        req.status != ProRequestStatus.cancelled &&
        req.status != ProRequestStatus.completed;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              req?.topic ?? 'Request thread',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Student · ${widget.userId.substring(0, widget.userId.length.clamp(0, 6))} · '
              '${req?.status.label ?? ''}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : req == null
              ? const Center(
                  child: Text(
                    'Request not found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: AppColors.accent.withValues(alpha: 0.12),
                      child: const Text(
                        'Replying as staff — the student sees these as volunteer messages',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: req.messages.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No messages yet. Say hello — the student is waiting.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      height: 1.4),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scroll,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              itemCount: req.messages.length,
                              itemBuilder: (context, i) {
                                final m = req.messages[i];
                                // Flip perspective: staff's own messages
                                // (isUser=false on the doc) render on the
                                // right; the student's on the left.
                                return ChatBubble(
                                  message: ChatMessage(
                                    text: m.text,
                                    isUser: !m.isUser,
                                    timestamp: m.timestamp,
                                  ),
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                enabled: !_sending && active,
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: active
                                      ? 'Reply to the student…'
                                      : 'This request is ${req.status.label.toLowerCase()}',
                                  hintStyle: TextStyle(
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.8),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surfaceCard,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _sending || !active ? null : _send,
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
