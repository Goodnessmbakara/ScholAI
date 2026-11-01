import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:scholai_app/core/services/gemini_live_service.dart';
import 'package:scholai_app/core/theme/scholai_colors.dart';
import 'package:scholai_app/core/utils/pcm_wav.dart';
import 'package:scholai_app/features/safety/domain/conversation_report.dart';
import 'package:scholai_app/features/safety/presentation/report_conversation_sheet.dart';
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
  // lowLatency (SoundPool on Android) lets slices start immediately —
  // the default mode re-buffers per play() and gaps between chunks.
  final _player = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
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
  final List<Uint8List> _playQueue = [];
  Timer? _playbackFlushTimer;
  bool _draining = false;
  bool _voiced = false;
  int _quietMs = 0;
  String _heardLine = '';
  String _replyLine = '';

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
        case LiveTranscriptReceivedEvent(:final text, :final isUser):
          setState(() {
            if (isUser) {
              _heardLine = _mergeTranscript(_heardLine, text);
              _liveSubtitle = _heardLine;
              _status = 'Hearing you...';
            } else {
              _replyLine = _mergeTranscript(_replyLine, text);
              _liveSubtitle = _replyLine;
              _status = 'Scholly is speaking...';
            }
            _isSpeaking = !isUser;
          });
        case LiveInterruptedEvent():
          _pcmBuffer.clear();
          _playQueue.clear();
          unawaited(_player.stop());
          setState(() {
            _isSpeaking = false;
            _status = _isMuted ? 'Listening to you...' : 'Mic on — speak freely';
          });
        case LiveTurnCompleteEvent():
          unawaited(_flushPlayback());
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
    // 24 kHz, 16-bit mono: 24 KB is about half a second — bigger slices
    // mean fewer play() transitions per reply.
    if (_pcmBuffer.length >= 24000) {
      _playQueue.add(pcmToWav(_pcmBuffer.takeBytes(), sampleRate: 24000));
      unawaited(_drainPlayback());
    }
    _playbackFlushTimer?.cancel();
    _playbackFlushTimer = Timer(const Duration(milliseconds: 280), () {
      unawaited(_flushPlayback());
    });
  }

  Future<void> _flushPlayback() async {
    _playbackFlushTimer?.cancel();
    if (_pcmBuffer.isEmpty) return;
    _playQueue.add(pcmToWav(_pcmBuffer.takeBytes(), sampleRate: 24000));
    await _drainPlayback();
  }

  /// PCM ms = bytes after the 44-byte WAV header / (24000 Hz × 2 bytes).
  int _wavDurationMs(Uint8List wav) => ((wav.length - 44).clamp(0, 1 << 62)) ~/ 48;

  Future<void> _drainPlayback() async {
    if (_draining) return;
    _draining = true;
    while (_playQueue.isNotEmpty) {
      final wav = _playQueue.removeAt(0);
      try {
        await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
        // Schedule the next slice for when this one ends rather than
        // awaiting onPlayerComplete — the platform event's latency was
        // the audible gap between chunks. 30 ms early start overlaps
        // slightly, which is cleaner than a dropout.
        final ms = _wavDurationMs(wav);
        await Future.delayed(Duration(milliseconds: ms > 30 ? ms - 30 : ms));
      } catch (_) {
        // Playback is best-effort on demo devices.
      }
    }
    _draining = false;
    if (!mounted) return;
    setState(() {
      _isSpeaking = false;
      if (_connected) {
        _status = _isMuted ? 'Listening... Tap a prompt or unmute to talk' : 'Mic on — speak freely';
      }
    });
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
          echoCancel: true,
          audioInterruption: AudioInterruptionMode.none,
          streamBufferSize: 3200,
        ),
      );

      // Mark unmuted before chunks arrive so the first packets are sent.
      _isMuted = false;
      _voiced = false;
      _quietMs = 0;

      _micSub = stream.listen(
        _onMicChunk,
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

  void _onMicChunk(Uint8List chunk) {
    if (_isMuted || !_connected || chunk.isEmpty || _draining) return;
    _service.sendAudioChunk(chunk);

    final loud = _peakPcm(chunk) > 1400;
    if (loud) {
      if (!_voiced && mounted) {
        _heardLine = '';
        setState(() => _status = 'Hearing you...');
      }
      _voiced = true;
      _quietMs = 0;
      return;
    }
    if (!_voiced) return;

    _quietMs += (chunk.length * 1000) ~/ 32000;
    if (_quietMs < 550) return;
    _service.endAudioStream();
    _voiced = false;
    _quietMs = 0;
    if (!mounted) return;
    setState(() => _status = 'Scholly is reflecting...');
  }

  int _peakPcm(Uint8List chunk) {
    var peak = 0;
    final data = ByteData.sublistView(chunk);
    for (var i = 0; i + 1 < chunk.length; i += 2) {
      final sample = data.getInt16(i, Endian.little).abs();
      if (sample > peak) peak = sample;
    }
    return peak;
  }

  String _mergeTranscript(String current, String next) {
    final incoming = next.trim();
    if (incoming.isEmpty) return current;
    if (current.isEmpty || incoming.startsWith(current)) return incoming;
    if (current.endsWith(incoming)) return current;
    final gap = current.endsWith(' ') || incoming.startsWith(' ') ? '' : ' ';
    return '$current$gap$incoming';
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
    _service.endAudioStream();
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
                  IconButton(
                    tooltip: 'Report this conversation',
                    icon: Icon(Icons.flag_outlined, color: colors.textSecondary),
                    onPressed: () => showReportConversationSheet(
                      context,
                      kind: ConversationKind.aiLive,
                      excerpt: _liveSubtitle,
                    ),
                  ),
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
