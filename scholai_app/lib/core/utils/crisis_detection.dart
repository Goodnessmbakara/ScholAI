/// Shared keyword-based crisis triage used across journal, live, and pro request.
class CrisisDetection {
  CrisisDetection._();

  static const keywords = [
    'kill myself',
    'end my life',
    'want to die',
    'suicide',
    'suicidal',
    'self harm',
    'self-harm',
    'hurt myself',
    'no point living',
    "don't want to be here",
    'better off dead',
    'overdose',
    'nothing dey for me',
    'i don tire for this life',
    'wetin i dey find for this world',
  ];

  static bool containsCrisisSignal(String text) {
    final lower = text.toLowerCase();
    return keywords.any((kw) => lower.contains(kw));
  }
}
