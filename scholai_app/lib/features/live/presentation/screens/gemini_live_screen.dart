import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/services/gemini_live_service.dart';
import 'package:scholai_app/core/theme/scholai_colors.dart';
import 'package:scholai_app/shared/widgets/scholai_mark.dart';

/// Gemini Live Audio Sanctuary — Real-Time Voice Decompression for Students.
/// Features a soothing pulsating ember orb, low-latency live transcripts,
/// and interactive voice controls.
class GeminiLiveScreen extends StatefulWidget {
  const GeminiLiveScreen({super.key});

  @override
  State<GeminiLiveScreen> createState() => _GeminiLiveScreenState();
}

class _GeminiLiveScreenState extends State<GeminiLiveScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final _service = GeminiLiveService.instance;
  StreamSubscription? _eventSub;

  String _status = 'Connecting to sanctuary...';
  String _liveSubtitle = 'Take a deep breath. Speak whenever you are ready...';
  bool _isSpeaking = false;
  bool _isMuted = false;

  final _quickPrompts = [
    'Exams are overwhelming me',
    'Help me breathe through anxiety',
    'I cannot sleep tonight',
    'Just feeling really lonely',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _initLiveConnection();
  }

  void _initLiveConnection() {
    _eventSub = _service.events.listen((event) {
      if (!mounted) return;

      switch (event) {
        case LiveConnectedEvent():
          setState(() {
            _status = 'Listening... Speak freely';
          });
        case LiveAudioReceivedEvent():
          setState(() {
            _status = 'Scholly is speaking...';
            _isSpeaking = true;
          });
        case LiveTranscriptReceivedEvent(:final text, :final isUser):
          setState(() {
            _liveSubtitle = text;
            _status = isUser ? 'Scholly is listening...' : 'Scholly is speaking...';
            _isSpeaking = !isUser;
          });
        case LiveInterruptedEvent():
          setState(() {
            _isSpeaking = false;
            _status = 'Listening to you...';
          });
        case LiveCrisisDetectedEvent():
          context.go('/crisis');
        case LiveErrorEvent():
          setState(() {
            _status = 'Offline demo mode';
            _liveSubtitle = 'Connection to live stream pending API key. Feel free to explore.';
          });
      }
    });

    _service.connect();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _service.disconnect();
    _pulseController.dispose();
    super.dispose();
  }

  void _sendQuickPrompt(String prompt) {
    _service.sendTextMessage(prompt);
    setState(() {
      _liveSubtitle = '"$prompt"';
      _status = 'Scholly is reflecting...';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'GEMINI LIVE AUDIO',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance close icon
                ],
              ),
              const Spacer(),

              // Pulsing Ember Orb Visual
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colors.primaryLight.withValues(alpha: 0.8),
                            colors.primary.withValues(alpha: 0.4),
                            colors.primaryDark.withValues(alpha: 0.05),
                          ],
                          stops: const [0.2, 0.6, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: _isSpeaking ? 0.4 : 0.2),
                            blurRadius: _isSpeaking ? 50 : 35,
                            spreadRadius: _isSpeaking ? 15 : 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: ScholAIMark(size: 64),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 36),

              // Status cue
              Text(
                _status,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Live Real-Time Subtitle Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.textPrimary.withValues(alpha: 0.06),
                  ),
                ),
                child: Text(
                  _liveSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Spacer(),

              // Quick Topic Pills
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final prompt = _quickPrompts[i];
                    return ActionChip(
                      label: Text(
                        prompt,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                        ),
                      ),
                      backgroundColor: colors.surfaceCard,
                      side: BorderSide(
                        color: colors.primary.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: () => _sendQuickPrompt(prompt),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Controls Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceCard,
                      foregroundColor: _isMuted ? colors.moodVeryLow : colors.textPrimary,
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: () {
                      setState(() => _isMuted = !_isMuted);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined, size: 20),
                    label: const Text('End Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
