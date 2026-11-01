import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/core/services/gemini_service.dart';
import 'package:scholai_app/features/journal/data/journal_local_store.dart';
import 'package:scholai_app/features/journal/presentation/widgets/chat_bubble.dart';
import 'package:scholai_app/features/safety/data/conversation_report_service.dart';
import 'package:scholai_app/features/safety/domain/conversation_report.dart';
import 'package:scholai_app/features/safety/presentation/report_conversation_sheet.dart';
import 'package:scholai_app/shared/models/chat_message.dart';

/// The Gemini-powered Socratic journaling screen.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  ChatSession? _session;
  bool _isLoading = false;
  int _exchangeCount = 0;
  final _speech = SpeechToText();
  bool _listening = false;
  String _speechBase = '';

  static const _maxExchanges = 5;

  // Opening prompt from Scholly
  static const _openingMessage = ChatMessage(
    text: "Hey 👋 I'm Scholly. This is your space — say whatever's on your mind. I'm listening.",
    isUser: false,
  );

  /// How much of the saved transcript feeds back into the Gemini session.
  static const _historySeedLimit = 40;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final saved = await JournalLocalStore.instance.load();
    if (!mounted) return;

    if (saved.isEmpty) {
      _messages.add(_openingMessage);
      unawaited(JournalLocalStore.instance.save(_messages));
    } else {
      setState(() {
        _messages.addAll(saved);
        _exchangeCount = saved.where((m) => m.isUser).length;
      });
    }

    if (!GeminiService.instance.hasApiKey) {
      setState(() {
        _messages.add(
          const ChatMessage(
            text:
                'AI key not embedded in this build. Run with --dart-define=GEMINI_API_KEY=... to enable Scholly.',
            isUser: false,
          ),
        );
      });
      return;
    }

    // Re-seed so Scholly remembers this thread, not just shows it.
    _session = saved.isEmpty
        ? GeminiService.instance.startSession()
        : GeminiService.instance.startSessionWithHistory(
            saved.length > _historySeedLimit
                ? saved.sublist(saved.length - _historySeedLimit)
                : saved,
          );
  }

  Future<void> _newConversation() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Start a new conversation?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This clears the transcript stored on this phone. Nothing was ever sent anywhere else.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start fresh',
                style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await JournalLocalStore.instance.clear();
    setState(() {
      _messages
        ..clear()
        ..add(_openingMessage);
      _exchangeCount = 0;
      _isLoading = false;
      _session = GeminiService.instance.hasApiKey
          ? GeminiService.instance.startSession()
          : null;
    });
    unawaited(JournalLocalStore.instance.save(_messages));
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (!GeminiService.instance.hasApiKey) {
      setState(() {
        _messages.add(
          const ChatMessage(
            text:
                'AI is offline — rebuild the app with --dart-define=GEMINI_API_KEY=your_key.',
            isUser: false,
          ),
        );
      });
      return;
    }

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    unawaited(JournalLocalStore.instance.save(_messages));
    _scrollToBottom();

    try {
      final session = _session ??= GeminiService.instance.startSession();
      final turn = await GeminiService.instance
          .sendMessage(session, text)
          .timeout(const Duration(seconds: 25));
      _session = turn.session;
      final response = turn.response;

      if (!mounted) return;

      switch (response) {
        case CrisisResponse():
          context.go('/crisis');
          return;

        case ReflectiveReply(:final text):
          _exchangeCount++;
          String reply = text;

          if (_exchangeCount == _maxExchanges) {
            reply +=
                '\n\n_You\'ve been doing a lot of reflection today. Have you thought about talking to someone in person? The UI counselling centre is always open._ 💛';
          }

          setState(() {
            _messages.add(ChatMessage(
                text: reply, isUser: false, timestamp: DateTime.now()));
            _isLoading = false;
          });
          unawaited(JournalLocalStore.instance.save(_messages));
          _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            text: 'Scholly couldn\'t reply just now ($e). Try again in a moment.',
            isUser: false,
          ),
        );
      });
    }
  }

  /// Voice input — typing shouldn't be the only way to talk to Scholly.
  /// Recognized words append onto whatever was already typed.
  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Speech recognition is not available here.')),
      );
      return;
    }
    _speechBase = _controller.text;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() {
          final base = _speechBase.trim();
          _controller.text = base.isEmpty
              ? r.recognizedWords
              : '$base ${r.recognizedWords}';
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
      listenOptions:
          SpeechListenOptions(listenFor: const Duration(seconds: 45)),
    );
    if (mounted) setState(() => _listening = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scholly', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Your reflection space', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New conversation',
            onPressed: _newConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          IconButton(
            tooltip: 'Report this conversation',
            onPressed: () => showReportConversationSheet(
              context,
              kind: ConversationKind.aiJournal,
              excerpt: ConversationReportService.excerptFrom(
                _messages,
                otherLabel: 'Scholly',
              ),
            ),
            icon: const Icon(Icons.flag_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('🔒 Private', style: TextStyle(fontSize: 11, color: AppColors.accent)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const ChatBubble.typing();
                }
                return ChatBubble(message: _messages[i]);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMid,
        border: Border(top: BorderSide(color: AppColors.surfaceCard)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: "Say whatever's on your mind...",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleListen,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _listening
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _listening ? Icons.mic : Icons.mic_none,
                color: _listening
                    ? AppColors.primaryLight
                    : AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
