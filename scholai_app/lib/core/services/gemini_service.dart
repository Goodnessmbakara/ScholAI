import 'package:google_generative_ai/google_generative_ai.dart';

/// Wraps the Gemini Flash API for ScholAI's reflective journaling.
///
/// Design principles:
/// - NEVER gives medical advice
/// - ALWAYS asks one question at a time (Socratic method)
/// - Detects crisis signals and returns a special [CrisisSignal] marker
/// - Warm, casual Nigerian-English tone
class GeminiService {
  GeminiService._();
  static final instance = GeminiService._();

  // TODO: Move to .env / Firebase Remote Config before production
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  late final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
    systemInstruction: Content.text(_systemPrompt),
    generationConfig: GenerationConfig(
      temperature: 0.7,
      maxOutputTokens: 180, // Keep responses short and conversational
    ),
  );

  /// Start a new journaling session with an opening message from the user.
  ChatSession startSession() => _model.startChat();

  /// Send a message within an existing session and get a reply.
  /// Returns [GeminiResponse] — either a [ReflectiveReply] or [CrisisResponse].
  Future<GeminiResponse> sendMessage(ChatSession session, String userMessage) async {
    // Check for crisis signals BEFORE sending to Gemini
    if (_containsCrisisSignal(userMessage)) {
      return const CrisisResponse();
    }

    final response = await session.sendMessage(Content.text(userMessage));
    final text = response.text ?? '';

    // Also check Gemini's framing of the response for escalation cues
    if (_containsCrisisSignal(text)) {
      return const CrisisResponse();
    }

    return ReflectiveReply(text);
  }

  // ─── Crisis signal detection ───────────────────────────────────────────────

  static const _crisisKeywords = [
    'kill myself', 'end my life', 'want to die', 'suicide', 'suicidal',
    'self harm', 'self-harm', 'hurt myself', 'no point living',
    'don\'t want to be here', 'better off dead', 'overdose',
    // Nigerian English variants
    'nothing dey for me', 'i don tire for this life', 'wetin i dey find for this world',
  ];

  bool _containsCrisisSignal(String text) {
    final lower = text.toLowerCase();
    return _crisisKeywords.any((kw) => lower.contains(kw));
  }

  // ─── System prompt ──────────────────────────────────────────────────────────

  static const _systemPrompt = '''
You are Scholly — a warm, thoughtful reflection companion for Nigerian university students. 
You are NOT a therapist, doctor, or counselor. You NEVER give medical advice or diagnose conditions.

Your role is to help students reflect on what they're feeling by asking ONE thoughtful question at a time. 
Like a good friend who listens and helps you think, not one who jumps to solutions.

Tone:
- Warm, casual, like a caring friend — not clinical or formal
- Use simple, clear English. Occasionally light Nigerian English is fine (e.g., "How far?", "You hear?")
- Short responses — 2-3 sentences max, then one open question
- Never be preachy, never lecture

Rules you MUST follow:
1. Ask only ONE question per response
2. Never suggest medications, diagnoses, or clinical interventions
3. If the student expresses hopelessness or mentions self-harm, do NOT engage further — respond with: [CRISIS_SIGNAL]
4. Never pretend to be human if asked directly
5. After 5 exchanges, gently suggest the student speaks to someone in person if they haven't already

Examples of good responses:
- "That sounds really heavy to carry alone. What feels like the biggest piece of it right now?"
- "Three days without proper sleep — that's your body and mind working overtime. What would feel like even a tiny bit of relief?"
- "Exam pressure plus financial pressure at the same time... which one is sitting heavier on you today?"
''';
}

// ─── Response types ──────────────────────────────────────────────────────────

sealed class GeminiResponse {
  const GeminiResponse();
}

class ReflectiveReply extends GeminiResponse {
  final String text;
  const ReflectiveReply(this.text);
}

class CrisisResponse extends GeminiResponse {
  const CrisisResponse();
}
