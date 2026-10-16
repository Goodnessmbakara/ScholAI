import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/journal/presentation/widgets/chat_bubble.dart';
import 'package:scholai_app/features/pro/data/models/pro_request.dart';
import 'package:scholai_app/features/pro/data/pro_request_service.dart';

/// Placeholder chat thread with a matched volunteer (local messages for MVP).
class ProChatScreen extends StatefulWidget {
  final String requestId;

  const ProChatScreen({super.key, required this.requestId});

  @override
  State<ProChatScreen> createState() => _ProChatScreenState();
}

class _ProChatScreenState extends State<ProChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  ProRequest? _request;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final req = await ProRequestService.instance.getRequest(widget.requestId);
    if (!mounted) return;
    setState(() {
      _request = req;
      _loading = false;
    });
    _scrollToEnd();
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
      final updated = await ProRequestService.instance.appendMessage(
        widget.requestId,
        text,
        isUser: true,
      );
      if (!mounted) return;
      setState(() => _request = updated);
      _scrollToEnd();
    } on CrisisDivertException {
      if (!mounted) return;
      context.go('/crisis');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send message.'),
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
    final title = req?.professionalName ?? 'Volunteer chat';

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            if (req?.professionalRole != null)
              Text(
                req!.professionalRole!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/pro-request/${widget.requestId}'),
            child: const Text('Status', style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : req == null
              ? const Center(
                  child: Text('Chat not found', style: TextStyle(color: AppColors.textSecondary)),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppColors.warning.withValues(alpha: 0.12),
                      child: const Text(
                        'Not anonymous · Demo thread (messages stay on this device / your account)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: req.messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (_sending && i == req.messages.length) {
                            return const ChatBubble.typing();
                          }
                          return ChatBubble(message: req.messages[i]);
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
                                enabled: !_sending &&
                                    req.status != ProRequestStatus.cancelled &&
                                    req.status != ProRequestStatus.completed,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Message your volunteer…',
                                  hintStyle: TextStyle(
                                    color: AppColors.textMuted.withValues(alpha: 0.8),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surfaceCard,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _sending ? null : _send,
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
