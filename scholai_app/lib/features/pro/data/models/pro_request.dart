import 'package:scholai_app/shared/models/chat_message.dart';

/// Lifecycle of a volunteer professional request.
enum ProRequestStatus {
  pending,
  matched,
  chatScheduled,
  callScheduled,
  completed,
  cancelled;

  String get label => switch (this) {
        ProRequestStatus.pending => 'Pending match',
        ProRequestStatus.matched => 'Matched',
        ProRequestStatus.chatScheduled => 'Chat scheduled',
        ProRequestStatus.callScheduled => 'Call scheduled',
        ProRequestStatus.completed => 'Completed',
        ProRequestStatus.cancelled => 'Cancelled',
      };

  String get wire => switch (this) {
        ProRequestStatus.pending => 'pending',
        ProRequestStatus.matched => 'matched',
        ProRequestStatus.chatScheduled => 'chat_scheduled',
        ProRequestStatus.callScheduled => 'call_scheduled',
        ProRequestStatus.completed => 'completed',
        ProRequestStatus.cancelled => 'cancelled',
      };

  static ProRequestStatus fromWire(String? value) {
    return switch (value) {
      'matched' => ProRequestStatus.matched,
      'chat_scheduled' => ProRequestStatus.chatScheduled,
      'call_scheduled' => ProRequestStatus.callScheduled,
      'completed' => ProRequestStatus.completed,
      'cancelled' => ProRequestStatus.cancelled,
      _ => ProRequestStatus.pending,
    };
  }
}

enum ProPreferredMode {
  chat,
  call;

  String get label => this == ProPreferredMode.chat ? 'Chat' : 'Call';
  String get wire => name;

  static ProPreferredMode fromWire(String? value) =>
      value == 'call' ? ProPreferredMode.call : ProPreferredMode.chat;
}

/// Student request to speak with a volunteer professional.
class ProRequest {
  final String id;
  final String? userId;
  final String topic;
  final ProPreferredMode preferredMode;
  final String timeWindow;
  final String? note;
  final bool consentGiven;
  final ProRequestStatus status;
  final String? professionalId;
  final String? professionalName;
  final String? professionalRole;
  final String? professionalPhone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  const ProRequest({
    required this.id,
    this.userId,
    required this.topic,
    required this.preferredMode,
    required this.timeWindow,
    this.note,
    required this.consentGiven,
    required this.status,
    this.professionalId,
    this.professionalName,
    this.professionalRole,
    this.professionalPhone,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  ProRequest copyWith({
    String? id,
    String? userId,
    String? topic,
    ProPreferredMode? preferredMode,
    String? timeWindow,
    String? note,
    bool? consentGiven,
    ProRequestStatus? status,
    String? professionalId,
    String? professionalName,
    String? professionalRole,
    String? professionalPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ProRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topic: topic ?? this.topic,
      preferredMode: preferredMode ?? this.preferredMode,
      timeWindow: timeWindow ?? this.timeWindow,
      note: note ?? this.note,
      consentGiven: consentGiven ?? this.consentGiven,
      status: status ?? this.status,
      professionalId: professionalId ?? this.professionalId,
      professionalName: professionalName ?? this.professionalName,
      professionalRole: professionalRole ?? this.professionalRole,
      professionalPhone: professionalPhone ?? this.professionalPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        if (userId != null) 'userId': userId,
        'topic': topic,
        'preferredMode': preferredMode.wire,
        'timeWindow': timeWindow,
        if (note != null) 'note': note,
        'consentGiven': consentGiven,
        'status': status.wire,
        if (professionalId != null) 'professionalId': professionalId,
        if (professionalName != null) 'professionalName': professionalName,
        if (professionalRole != null) 'professionalRole': professionalRole,
        if (professionalPhone != null) 'professionalPhone': professionalPhone,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages
            .map((m) => {
                  'text': m.text,
                  'isUser': m.isUser,
                  if (m.timestamp != null) 'at': m.timestamp!.toIso8601String(),
                })
            .toList(),
      };

  factory ProRequest.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawMessages = map['messages'] as List<dynamic>? ?? const [];
    return ProRequest(
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String?,
      topic: map['topic'] as String? ?? '',
      preferredMode: ProPreferredMode.fromWire(map['preferredMode'] as String?),
      timeWindow: map['timeWindow'] as String? ?? 'anytime',
      note: map['note'] as String?,
      consentGiven: map['consentGiven'] as bool? ?? false,
      status: ProRequestStatus.fromWire(map['status'] as String?),
      professionalId: map['professionalId'] as String?,
      professionalName: map['professionalName'] as String?,
      professionalRole: map['professionalRole'] as String?,
      professionalPhone: map['professionalPhone'] as String?,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      messages: rawMessages.map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        return ChatMessage(
          text: m['text'] as String? ?? '',
          isUser: m['isUser'] as bool? ?? false,
          timestamp: _parseDate(m['at']),
        );
      }).toList(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Firestore Timestamp (duck-typed to avoid hard import in model).
    try {
      return (value as dynamic).toDate() as DateTime?;
    } catch (_) {
      return null;
    }
  }
}

/// Topic chips for the request form (non-clinical wording).
const kProTopics = [
  'Exams',
  'Money',
  'Relationships',
  'Habits',
];

const kProTimeWindows = [
  'Morning (8am–12pm)',
  'Afternoon (12pm–5pm)',
  'Evening (5pm–9pm)',
  'Anytime',
];
