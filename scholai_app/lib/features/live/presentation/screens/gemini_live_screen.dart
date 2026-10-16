import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:scholai_app/core/services/gemini_live_service.dart';
import 'package:scholai_app/core/theme/scholai_colors.dart';
import 'package:scholai_app/core/utils/pcm_wav.dart';
import 'package:scholai_app/shared/widgets/scholai_mark.dart';

/// Gemini Live Audio Sanctuary — real-time voice decompression for students.
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
  final _player = AudioPlayer();
  final _recorder = AudioRecorder();
  StreamSubscription? _eventSub;
  StreamSubscription<Uint8List>? _micSub;

  String _status = 'Connecting to sanctuary...';
  String _liveSubtitle = 'Take a deep breath. Speak whenever you are ready...';
  bool _isSpeaking = false;
  bool _isMuted = true;
  bool _connected = false;
  bool _micStarting = false;

  final BytesBuilder _pcmBuffer = BytesBuilder(copy: false);
  Timer? _playbackFlushTimer;

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
            _connected = true;
            _status = _isMuted
                ? 'Listening... Tap a prompt or unmute to talk'
                : 'Mic on — speak freely';
          });
        case LiveAudioReceivedEvent(:final audioBytes):
          _enqueuePcm(audioBytes);
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
          _pcmBuffer.clear();
          setState(() {
            _isSpeaking = false;
            _status = _isMuted ? 'Listening to you...' : 'Mic on — speak freely';
          });
        case LiveCrisisDetectedEvent():
          unawaited(_stopMicStreaming());
          context.go('/crisis');
        case LiveErrorEvent(:final message):
          unawaited(_stopMicStreaming());
          setState(() {
            _connected = false;
            _isMuted = true;
            _status = 'Connection issue';
            _liveSubtitle = message;
          });
      }
    });

    _service.connect();
  }

  void _enqueuePcm(Uint8List chunk) {
    _pcmBuffer.add(chunk);
    _playbackFlushTimer?.cancel();
    // Coalesce small Live packets into a playable WAV burst.
    _playbackFlushTimer = Timer(const Duration(milliseconds: 280), _flushPlayback);
  }

  Future<void> _flushPlayback() async {
    if (_pcmBuffer.isEmpty) return;
    final pcm = _pcmBuffer.toBytes();
    _pcmBuffer.clear();
    final wav = pcmToWav(pcm, sampleRate: 24000);
    try {
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    } catch (_) {
      // Playback is best-effort on demo devices.
    }
  }

  Future<void> _toggleMute() async {
    if (_micStarting) return;

    if (!_isMuted) {
      await _stopMicStreaming();
      if (!mounted) return;
      setState(() {
        _isMuted = true;
        _status = 'Mic muted — use a quick prompt';
      });
      return;
    }

    if (!_connected) {
      setState(() {
        _liveSubtitle = 'Still connecting — try again in a moment.';
      });
      return;
    }

    await _startMicStreaming();
  }

  Future<void> _startMicStreaming() async {
    if (_micStarting || !_connected) return;
    _micStarting = true;

    try {
      final allowed = await _recorder.hasPermission();
      if (!allowed) {
        if (!mounted) return;
        setState(() {
          _isMuted = true;
          _status = 'Mic permission denied';
          _liveSubtitle =
              'Enable the microphone in Settings, or use a quick prompt below.';
        });
        return;
      }

      await _stopMicStreaming();

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      // Mark unmuted before chunks arrive so the first packets are sent.
      _isMuted = false;

      _micSub = stream.listen(
        (chunk) {
          if (_isMuted || !_connected || chunk.isEmpty) return;
          _service.sendAudioChunk(chunk);
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _isMuted = true;
            _status = 'Mic error — use a quick prompt';
          });
          unawaited(_stopMicStreaming());
        },
      );

      if (!mounted) {
        await _stopMicStreaming();
        return;
      }

      setState(() {
        _status = 'Mic on — speak freely';
      });

    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isMuted = true;
        _status = 'Could not start mic';
        _liveSubtitle = 'Check microphone permission, or use a quick prompt.';
      });
      await _stopMicStreaming();
    } finally {
      _micStarting = false;
    }
  }

  Future<void> _stopMicStreaming() async {
    await _micSub?.cancel();
    _micSub = null;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {
      // Best-effort stop on teardown.
    }
  }

  @override
  void dispose() {
    _playbackFlushTimer?.cancel();
    _eventSub?.cancel();
    _micSub?.cancel();
    _micSub = null;
    _recorder.dispose();
    _service.disconnect();
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }


  void _sendQuickPrompt(String prompt) {
    if (!_connected) {
      setState(() {
        _liveSubtitle = 'Still connecting — try again in a moment.';
      });
      return;
    }
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
                            color: _connected ? colors.primaryLight : colors.textMuted,
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
                  const SizedBox(width: 48),
                ],
              ),
              const Spacer(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        tooltip: _isMuted ? 'Unmute mic' : 'Mute mic',
                        icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                        style: IconButton.styleFrom(
                          backgroundColor: _isMuted
                              ? colors.surfaceCard
                              : colors.primary.withValues(alpha: 0.25),
                          foregroundColor:
                              _isMuted ? colors.moodVeryLow : colors.primaryLight,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: _micStarting ? null : _toggleMute,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isMuted ? 'Mic off' : 'Mic streaming',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isMuted ? colors.textMuted : colors.primaryLight,
                        ),
                      ),
                    ],
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
