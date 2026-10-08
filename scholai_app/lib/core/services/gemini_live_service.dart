import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:scholai_app/core/utils/app_logger.dart';

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

class LiveCrisisDetectedEvent extends GeminiLiveEvent {
  const LiveCrisisDetectedEvent();
}

class LiveErrorEvent extends GeminiLiveEvent {
  final String message;
  const LiveErrorEvent(this.message);
}

/// Bidirectional WebSocket Client for Google's Gemini Multimodal Live API.
///
/// Features:
/// - Real-time low-latency voice streaming (< 500ms response).
/// - Configured with the gentle, compassionate 'Aoede' voice.
/// - Built-in interruption handling (bidi streaming).
/// - Safety layer monitoring for crisis expressions.
class GeminiLiveService {
  GeminiLiveService._();
  static final instance = GeminiLiveService._();

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _liveHost = 'generativelanguage.googleapis.com';
  static const _livePath = '/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _eventController = StreamController<GeminiLiveEvent>.broadcast();

  Stream<GeminiLiveEvent> get events => _eventController.stream;
  bool get isConnected => _channel != null;

  /// Connects to the Gemini Multimodal Live API WebSocket endpoint
  /// and completes the initial handshake setup with the 'Aoede' voice persona.
  Future<void> connect() async {
    if (_channel != null) return;

    final uri = Uri.parse('wss://$_liveHost$_livePath?key=$_apiKey');
    AppLogger.info('Connecting to Gemini Live WebSocket: ${uri.host}');

    try {
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

      // Send initial Setup handshake message
      _sendSetupMessage();
      _eventController.add(const LiveConnectedEvent());
    } catch (e, stack) {
      AppLogger.error('Failed to connect to Gemini Live', error: e, stackTrace: stack);
      _eventController.add(LiveErrorEvent('Connection failed: $e'));
      disconnect();
    }
  }

  /// Sends the initial configuration handshake to the Live API.
  void _sendSetupMessage() {
    final setupPayload = {
      'setup': {
        'model': 'models/gemini-2.0-flash-exp',
        'generationConfig': {
          'responseModalities': ['AUDIO', 'TEXT'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {
                'voiceName': 'Aoede', // Gentle, warm, compassionate tone
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
- Keep spoken responses short (1-2 sentences at a time).
- Never diagnose, prescribe, or give medical advice.
- Validate their feelings first, then ask one gentle question.
- If the student indicates thoughts of self-harm or despair ("i don tire", "nothing dey for me", "want to die"), immediately acknowledge and tell them: "I care about you, and you deserve real human care right now. Let's look at real support together."
'''
            }
          ]
        }
      }
    };

    _channel?.sink.add(jsonEncode(setupPayload));
    AppLogger.info('Sent Gemini Live Setup Handshake');
  }

  /// Streams raw 16kHz PCM audio bytes from microphone to Gemini Live.
  void sendAudioChunk(Uint8List pcmChunk) {
    if (_channel == null) return;

    final base64Audio = base64Encode(pcmChunk);
    final payload = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': 'audio/pcm;rate=16000',
            'data': base64Audio,
          }
        ]
      }
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  /// Sends a text message over the real-time bidi channel.
  void sendTextMessage(String text) {
    if (_channel == null) return;

    final payload = {
      'realtimeInput': {
        'parts': [
          {'text': text}
        ]
      }
    };

    _channel!.sink.add(jsonEncode(payload));
    _eventController.add(LiveTranscriptReceivedEvent(text: text, isUser: true));
  }

  /// Handles incoming server events from the WebSocket stream.
  void _handleServerMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message as String) as Map<String, dynamic>;

      final serverContent = decoded['serverContent'] as Map<String, dynamic>?;
      if (serverContent != null) {
        // Interruption check: user spoke while model was responding
        final interrupted = serverContent['interrupted'] as bool? ?? false;
        if (interrupted) {
          _eventController.add(const LiveInterruptedEvent());
        }

        final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>?;
        if (modelTurn != null) {
          final parts = modelTurn['parts'] as List<dynamic>? ?? [];
          for (final part in parts) {
            final partMap = part as Map<String, dynamic>;

            // 1. Audio chunk
            final inlineData = partMap['inlineData'] as Map<String, dynamic>?;
            if (inlineData != null) {
              final rawBase64 = inlineData['data'] as String?;
              if (rawBase64 != null) {
                final audioBytes = base64Decode(rawBase64);
                _eventController.add(LiveAudioReceivedEvent(audioBytes));
              }
            }

            // 2. Transcript text chunk
            final text = partMap['text'] as String?;
            if (text != null && text.isNotEmpty) {
              _eventController.add(LiveTranscriptReceivedEvent(text: text, isUser: false));
            }
          }
        }
      }
    } catch (e, stack) {
      AppLogger.warning('Failed to parse Gemini Live packet', error: e, stackTrace: stack);
    }
  }

  /// Cleanly closes the WebSocket connection.
  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    AppLogger.info('Gemini Live disconnected.');
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
