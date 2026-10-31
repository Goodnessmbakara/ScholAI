import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/features/safety/domain/conversation_report.dart';
import 'package:scholai_app/shared/models/chat_message.dart';

class ConversationReportService {
  ConversationReportService._();
  static final instance = ConversationReportService._();

  FirebaseFirestore? get _db {
    if (Firebase.apps.isEmpty) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> submit({
    required ConversationKind kind,
    required String note,
    String excerpt = '',
    String requestId = '',
    String counterpartName = '',
  }) async {
    final db = _db;
    final uid = AuthService.instance.uid;
    if (db == null || uid == null) {
      throw StateError('Firebase is not ready.');
    }
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      throw StateError('Add a short note so we know what to look at.');
    }
    await db.collection('conversationReports').add({
      'reporterUid': uid,
      'kind': kind.wire,
      'note': _clip(trimmed, 1000),
      'excerpt': _clip(excerpt.trim(), 3500),
      'requestId': _clip(requestId.trim(), 120),
      'counterpartName': _clip(counterpartName.trim(), 120),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ConversationReport>> listRecent() async {
    final db = _db;
    if (db == null) return const [];
    final snap = await db
        .collection('conversationReports')
        .orderBy('createdAt', descending: true)
        .limit(40)
        .get();
    return snap.docs
        .map((doc) => ConversationReport.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<void> markReviewed(String id) async {
    final db = _db;
    if (db == null) throw StateError('Firebase is not ready.');
    await db.collection('conversationReports').doc(id).update({
      'status': 'reviewed',
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  static String excerptFrom(List<ChatMessage> messages, {required String otherLabel}) {
    if (messages.isEmpty) return '';
    final tail = messages.length > 8 ? messages.sublist(messages.length - 8) : messages;
    return tail
        .map((message) => '${message.isUser ? 'Student' : otherLabel}: ${message.text.trim()}')
        .join('\n');
  }

  static String _clip(String value, int max) {
    if (value.length <= max) return value;
    return value.substring(0, max);
  }
}
