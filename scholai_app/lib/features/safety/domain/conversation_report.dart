enum ConversationKind {
  aiJournal,
  aiLive,
  professional;

  String get wire => switch (this) {
        ConversationKind.aiJournal => 'aiJournal',
        ConversationKind.aiLive => 'aiLive',
        ConversationKind.professional => 'professional',
      };

  String get label => switch (this) {
        ConversationKind.aiJournal => 'AI journal',
        ConversationKind.aiLive => 'AI voice',
        ConversationKind.professional => 'Professional',
      };

  static ConversationKind fromWire(String? value) => switch (value) {
        'aiLive' => ConversationKind.aiLive,
        'professional' => ConversationKind.professional,
        _ => ConversationKind.aiJournal,
      };
}

class ConversationReport {
  final String id;
  final String reporterUid;
  final ConversationKind kind;
  final String note;
  final String excerpt;
  final String requestId;
  final String counterpartName;
  final String status;

  const ConversationReport({
    required this.id,
    required this.reporterUid,
    required this.kind,
    required this.note,
    required this.excerpt,
    required this.requestId,
    required this.counterpartName,
    required this.status,
  });

  bool get isOpen => status == 'open';

  factory ConversationReport.fromMap(Map<String, dynamic> map, {required String id}) {
    return ConversationReport(
      id: id,
      reporterUid: map['reporterUid'] as String? ?? '',
      kind: ConversationKind.fromWire(map['kind'] as String?),
      note: map['note'] as String? ?? '',
      excerpt: map['excerpt'] as String? ?? '',
      requestId: map['requestId'] as String? ?? '',
      counterpartName: map['counterpartName'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
    );
  }
}
