import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/core/services/gemini_service.dart';
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

  static const _maxExchanges = 5;

  // Opening prompt from Scholly
  static const _openingMessage = ChatMessage(
    text: "Hey 👋 I'm Scholly. This is your space — say whatever's on your mind. I'm listening.",
    isUser: false,
  );

  @override
  void initState() {
    super.initState();
    if (GeminiService.instance.hasApiKey) {
      _session = GeminiService.instance.startSession();
    }
    _messages.add(_openingMessage);
    if (!GeminiService.instance.hasApiKey) {
      _messages.add(
        const ChatMessage(
          text:
              'AI key not embedded in this build. Run with --dart-define=GEMINI_API_KEY=... to enable Scholly.',
          isUser: false,
        ),
      );
    }
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
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final session = _session ??= GeminiService.instance.startSession();
      final turn = await GeminiService.instance.sendMessage(session, text);
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
            _messages.add(ChatMessage(text: reply, isUser: false));
            _isLoading = false;
          });
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
