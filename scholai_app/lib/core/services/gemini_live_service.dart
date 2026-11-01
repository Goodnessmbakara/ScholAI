import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:scholai_app/core/utils/app_config.dart';
import 'package:scholai_app/core/utils/app_logger.dart';
import 'package:scholai_app/core/utils/crisis_detection.dart';


/// Event stream types emitted by the Gemini Multimodal Live API.
sealed class GeminiLiveEvent {
  const GeminiLiveEvent();
}

class LiveConnectedEvent extends GeminiLiveEvent {
  const LiveConnectedEvent();
}

class LiveAudioReceivedEvent extends GeminiLiveEvent {
  final Uint8List audioBytes;
  const LiveAudioReceivedEvent(this.audioBytes);
}

class LiveTranscriptReceivedEvent extends GeminiLiveEvent {
  final String text;
  final bool isUser;
  const LiveTranscriptReceivedEvent({required this.text, required this.isUser});
}

class LiveInterruptedEvent extends GeminiLiveEvent {
  const LiveInterruptedEvent();
}

class LiveTurnCompleteEvent extends GeminiLiveEvent {
  const LiveTurnCompleteEvent();
}

class LiveCrisisDetectedEvent extends GeminiLiveEvent {
  const LiveCrisisDetectedEvent();
}

class LiveErrorEvent extends GeminiLiveEvent {
  final String message;
  const LiveErrorEvent(this.message);
}

/// Bidirectional WebSocket client for Gemini Live (native audio).
class GeminiLiveService {
  GeminiLiveService._();
  static final instance = GeminiLiveService._();

  static const _liveHost = 'generativelanguage.googleapis.com';
  // Current Live API websocket. Docs: get-started-websocket, updated 2026-09-15.
  static const _livePath =
      '/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';
  static const _liveModel = 'models/gemini-3.8-live';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _eventController = StreamController<GeminiLiveEvent>.broadcast();
  Completer<void>? _setupCompleter;
  bool _ready = false;

  Stream<GeminiLiveEvent> get events => _eventController.stream;
  bool get isConnected => _channel != null && _ready;
  bool get hasApiKey => AppConfig.hasGeminiApiKey;

  /// Connects and waits for `setupComplete` before accepting turns.
  /// [memoryContext] is appended to the system prompt — recent journal/voice
  /// turns so Scholly keeps a memory pool across sessions and modalities.
  Future<void> connect({String memoryContext = ''}) async {
    if (_channel != null) return;

    if (!hasApiKey) {
      _eventController.add(
        const LiveErrorEvent(
          'GEMINI_API_KEY missing. Copy .env.example → .env, or pass '
          '--dart-define=GEMINI_API_KEY=...',
        ),
      );
      return;
    }

    final apiKey = AppConfig.geminiApiKey;
    final uri = Uri.parse('wss://$_liveHost$_livePath?key=$apiKey');
    AppLogger.info('Connecting to Gemini Live WebSocket: ${uri.host}');

    try {
      _setupCompleter = Completer<void>();
      _ready = false;
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _handleServerMessage,
        onError: (err) {
          AppLogger.error('Gemini Live WebSocket error', error: err);
          _eventController.add(LiveErrorEvent(err.toString()));
          disconnect();
        },
        onDone: () {
          AppLogger.info('Gemini Live WebSocket connection closed.');
          disconnect();
        },
      );

      _sendSetupMessage();
      await _setupCompleter!.future.timeout(const Duration(seconds: 20));
      _ready = true;
      _eventController.add(const LiveConnectedEvent());
    } catch (e, stack) {
      AppLogger.error('Failed to connect to Gemini Live', error: e, stackTrace: stack);
      _eventController.add(LiveErrorEvent('Connection failed: $e'));
      disconnect();
    }
  }

  void _sendSetupMessage() {
    final setupPayload = {
      'setup': {
        'model': _liveModel,
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {
                'voiceName': 'Aoede',
              },
            },
          },
        },
        'systemInstruction': {
          'parts': [
            {
              'text': '''
You are Scholly — a warm, calm, grounding voice companion for Nigerian university students.
You are speaking out loud to a student who might be exhausted, anxious, or decompressing late at night.

Guidelines for spoken audio:
- Speak slowly, with a soft, peaceful, and gentle cadence.
- This is a real conversation, not a monologue — go deeper when the student
  wants to talk, but keep each turn to a few sentences and leave natural
  pauses so they can jump in. If they start speaking while you talk,
  yield immediately and listen.
- Never diagnose, prescribe, or give medical advice.
- Validate their feelings first, then ask one gentle question.
- If the student indicates thoughts of self-harm or despair, immediately acknowledge and urge real human support.
${memoryContext.isEmpty ? '' : '\nWhat the student has shared recently (memory):\n$memoryContext'}
'''
            }
          ]
        },
        'inputAudioTranscription': {},
        'outputAudioTranscription': {},
        'realtimeInputConfig': {
          'automaticActivityDetection': {
            'disabled': false,
            'startOfSpeechSensitivity': 'START_SENSITIVITY_HIGH',
            'endOfSpeechSensitivity': 'END_SENSITIVITY_HIGH',
            'prefixPaddingMs': 200,
            'silenceDurationMs': 500,
          },
        },
      }
    };

    _channel?.sink.add(jsonEncode(setupPayload));
    AppLogger.info('Sent Gemini Live Setup Handshake');
  }

  /// Streams raw 16kHz PCM audio bytes from microphone to Gemini Live.
  void sendAudioChunk(Uint8List pcmChunk) {
    if (!isConnected) return;

    final payload = {
      'realtimeInput': {
        'audio': {
          'mimeType': 'audio/pcm;rate=16000',
          'data': base64Encode(pcmChunk),
        }
      }
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  /// Tells the server the microphone stream paused, so it can close the turn.
  void endAudioStream() {
    if (!isConnected) return;
    _channel!.sink.add(jsonEncode({
      'realtimeInput': {'audioStreamEnd': true},
    }));
  }

  /// Sends a text turn. Live expects `realtimeInput.text`, not `clientContent`.
  void sendTextMessage(String text) {
    if (!isConnected) {
      _eventController.add(
        const LiveErrorEvent('Not connected to Live yet. Wait for "Listening..."'),
      );
      return;
    }

    if (_containsCrisisSignal(text)) {
      _eventController.add(const LiveCrisisDetectedEvent());
      return;
    }

    final payload = {
      'realtimeInput': {
        'text': text,
      },
    };

    _channel!.sink.add(jsonEncode(payload));
    _eventController.add(LiveTranscriptReceivedEvent(text: text, isUser: true));
  }

  void _handleServerMessage(dynamic message) {
    try {
      final raw = switch (message) {
        String text => text,
        List<int> bytes => utf8.decode(bytes),
        _ => null,
      };
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      if (decoded.containsKey('setupComplete')) {
        if (!(_setupCompleter?.isCompleted ?? true)) {
          _setupCompleter!.complete();
        }
        return;
      }

      if (decoded.containsKey('error')) {
        final err = decoded['error'];
        _eventController.add(LiveErrorEvent(err.toString()));
        return;
      }

      final serverContent = decoded['serverContent'] as Map<String, dynamic>?;
      if (serverContent == null) return;

      if (serverContent['interrupted'] == true) {
        _eventController.add(const LiveInterruptedEvent());
      }

      if (serverContent['turnComplete'] == true) {
        _eventController.add(const LiveTurnCompleteEvent());
      }

      final inputTx = serverContent['inputTranscription'] as Map<String, dynamic>?;
      final inputText = inputTx?['text'] as String?;
      if (inputText != null && inputText.isNotEmpty) {
        if (_containsCrisisSignal(inputText)) {
          _eventController.add(const LiveCrisisDetectedEvent());
          return;
        }
        _eventController.add(
          LiveTranscriptReceivedEvent(text: inputText, isUser: true),
        );
      }

      final outputTx = serverContent['outputTranscription'] as Map<String, dynamic>?;
      final outputText = outputTx?['text'] as String?;
      if (outputText != null && outputText.isNotEmpty) {
        if (_containsCrisisSignal(outputText)) {
          _eventController.add(const LiveCrisisDetectedEvent());
          return;
        }
        _eventController.add(
          LiveTranscriptReceivedEvent(text: outputText, isUser: false),
        );
      }

      final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>?;
      if (modelTurn != null) {
        final parts = modelTurn['parts'] as List<dynamic>? ?? [];
        for (final part in parts) {
          final partMap = part as Map<String, dynamic>;

          final inlineData = partMap['inlineData'] as Map<String, dynamic>?;
          if (inlineData != null) {
            final rawBase64 = inlineData['data'] as String?;
            if (rawBase64 != null) {
              _eventController.add(LiveAudioReceivedEvent(base64Decode(rawBase64)));
            }
          }

          final text = partMap['text'] as String?;
          if (text != null && text.isNotEmpty) {
            if (_containsCrisisSignal(text)) {
              _eventController.add(const LiveCrisisDetectedEvent());
              return;
            }
            _eventController.add(
              LiveTranscriptReceivedEvent(text: text, isUser: false),
            );
          }
        }
      }
    } catch (e, stack) {
      AppLogger.warning('Failed to parse Gemini Live packet', error: e, stackTrace: stack);
    }
  }

  bool _containsCrisisSignal(String text) =>
      CrisisDetection.containsCrisisSignal(text);

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _ready = false;
    if (!(_setupCompleter?.isCompleted ?? true)) {
      _setupCompleter!.completeError(StateError('Disconnected before setup'));
    }
    _setupCompleter = null;
    AppLogger.info('Gemini Live disconnected.');
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
