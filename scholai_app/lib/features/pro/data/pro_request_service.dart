import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/core/utils/app_logger.dart';
import 'package:scholai_app/core/utils/crisis_detection.dart';
import 'package:scholai_app/features/pro/data/models/pro_request.dart';
import 'package:scholai_app/features/pro/data/models/professional.dart';
import 'package:scholai_app/shared/models/chat_message.dart';

/// Thrown when topic/note indicates self-harm — UI should route to `/crisis`.
class CrisisDivertException implements Exception {
  const CrisisDivertException();
}

/// Intake + queue + matching for volunteer professionals.
///
/// Prefers Firestore (`/users/{uid}/proRequests`, `/professionals`) when Auth
/// works; falls back to SharedPreferences for local/demo mode.
class ProRequestService {
  ProRequestService._();
  static final instance = ProRequestService._();

  static const _localKey = 'scholai_pro_requests_v1';
  final _uuid = const Uuid();

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  FirebaseFirestore? get _db {
    if (!_firebaseReady) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? _userRequestsRef() {
    final db = _db;
    final uid = AuthService.instance.uid;
    if (db == null || uid == null) return null;
    return db.collection('users').doc(uid).collection('proRequests');
  }

  /// Returns seed roster, attempting Firestore `/professionals` first.
  Future<List<Professional>> listProfessionals() async {
    final db = _db;
    if (db != null) {
      try {
        final snap = await db.collection('professionals').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => Professional.fromMap(d.data(), id: d.id))
              .toList();
        }
        // Soft-seed once when collection is empty (may fail under locked rules).
        await _seedProfessionals(db);
      } catch (e, stack) {
        AppLogger.warning(
          'Professionals Firestore read failed; using local seed',
          error: e,
          stackTrace: stack,
        );
      }
    }
    return List.unmodifiable(kSeedProfessionals);
  }

  Future<void> _seedProfessionals(FirebaseFirestore db) async {
    final batch = db.batch();
    for (final pro in kSeedProfessionals) {
      batch.set(db.collection('professionals').doc(pro.id), pro.toMap());
    }
    await batch.commit();
    AppLogger.info('Seeded ${kSeedProfessionals.length} mock professionals.');
  }

  Future<List<ProRequest>> listRequests() async {
    final ref = _userRequestsRef();
    if (ref != null) {
      try {
        final snap = await ref.orderBy('createdAt', descending: true).get();
        return snap.docs
            .map((d) => ProRequest.fromMap(d.data(), id: d.id))
            .toList();
      } catch (e, stack) {
        AppLogger.warning(
          'proRequests Firestore list failed; using local cache',
          error: e,
          stackTrace: stack,
        );
      }
    }
    return _loadLocal();
  }

  Future<ProRequest?> getRequest(String id) async {
    final ref = _userRequestsRef();
    if (ref != null) {
      try {
        final doc = await ref.doc(id).get();
        if (doc.exists && doc.data() != null) {
          return ProRequest.fromMap(doc.data()!, id: doc.id);
        }
      } catch (e, stack) {
        AppLogger.warning(
          'proRequest Firestore get failed; checking local',
          error: e,
          stackTrace: stack,
        );
      }
    }
    final local = await _loadLocal();
    try {
      return local.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Creates a pending request, then auto-matches a volunteer for MVP.
  /// Throws [CrisisDivertException] when note/topic signals self-harm.
  Future<ProRequest> submitRequest({
    required String topic,
    required ProPreferredMode preferredMode,
    required String timeWindow,
    String? note,
    required bool consentGiven,
  }) async {
    if (!consentGiven) {
      throw ArgumentError('Consent is required to request a volunteer.');
    }

    final crisisText = '${topic.trim()} ${note ?? ''}'.trim();
    if (CrisisDetection.containsCrisisSignal(crisisText)) {
      throw const CrisisDivertException();
    }

    final now = DateTime.now();
    final id = _uuid.v4();
    var request = ProRequest(
      id: id,
      userId: AuthService.instance.uid,
      topic: topic,
      preferredMode: preferredMode,
      timeWindow: timeWindow,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      consentGiven: true,
      status: ProRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    await _persist(request);

    // MVP auto-match: pick a volunteer who supports the preferred mode.
    request = await _autoMatch(request);
    return request;
  }

  Future<ProRequest> _autoMatch(ProRequest request) async {
    final pros = await listProfessionals();
    final mode = request.preferredMode.wire;
    final candidates = pros
        .where((p) => p.availableModes.contains(mode))
        .toList();
    final pool = candidates.isNotEmpty ? candidates : pros;
    if (pool.isEmpty) return request;

    // Light topic affinity for demo realism.
    final topic = request.topic.toLowerCase();
    Professional pick = pool.first;
    for (final p in pool) {
      final hay = '${p.specialty} ${p.role}'.toLowerCase();
      if (topic.contains('exam') && hay.contains('academic')) {
        pick = p;
        break;
      }
      if (topic.contains('money') && hay.contains('money')) {
        pick = p;
        break;
      }
      if (topic.contains('relationship') && hay.contains('relationship')) {
        pick = p;
        break;
      }
      if (topic.contains('habit') && hay.contains('habit')) {
        pick = p;
        break;
      }
    }

    final matched = request.copyWith(
      status: ProRequestStatus.matched,
      professionalId: pick.id,
      professionalName: pick.name,
      professionalRole: pick.role,
      professionalPhone: pick.phone,
      updatedAt: DateTime.now(),
      messages: [
        ChatMessage(
          text:
              'Hi — I\'m ${pick.name} (${pick.role}). I saw your note about '
              '${request.topic.toLowerCase()}. When you\'re ready, reply here '
              'or request a call. Reminder: this session is not anonymous.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
    await _persist(matched);
    return matched;
  }

  Future<ProRequest> scheduleChat(String requestId) async {
    final current = await getRequest(requestId);
    if (current == null) throw StateError('Request not found');
    final updated = current.copyWith(
      status: ProRequestStatus.chatScheduled,
      updatedAt: DateTime.now(),
    );
    await _persist(updated);
    return updated;
  }

  /// Marks call scheduled. Caller may launch `tel:` when [professionalPhone] exists.
  Future<ProRequest> requestCall(String requestId) async {
    final current = await getRequest(requestId);
    if (current == null) throw StateError('Request not found');
    final updated = current.copyWith(
      status: ProRequestStatus.callScheduled,
      preferredMode: ProPreferredMode.call,
      updatedAt: DateTime.now(),
      messages: [
        ...current.messages,
        ChatMessage(
          text: current.professionalPhone != null
              ? 'Call requested. You can dial the volunteer now, or wait for a callback in your time window (${current.timeWindow}).'
              : 'Call requested. ${current.professionalName ?? 'Your volunteer'} will call you back during ${current.timeWindow}. (No direct number on file — demo callback.)',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
    await _persist(updated);
    return updated;
  }

  Future<ProRequest> appendMessage(String requestId, String text, {required bool isUser}) async {
    final current = await getRequest(requestId);
    if (current == null) throw StateError('Request not found');

    if (isUser && CrisisDetection.containsCrisisSignal(text)) {
      throw const CrisisDivertException();
    }

    final messages = [
      ...current.messages,
      ChatMessage(text: text, isUser: isUser, timestamp: DateTime.now()),
    ];

    // Simple local echo for MVP when user sends.
    if (isUser) {
      messages.add(
        ChatMessage(
          text:
              'Thanks for sharing that. I\'m here with you — take your time. '
              '(Demo reply · real matching comes later.)',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    var status = current.status;
    if (status == ProRequestStatus.matched || status == ProRequestStatus.pending) {
      status = ProRequestStatus.chatScheduled;
    }

    final updated = current.copyWith(
      messages: messages,
      status: status,
      updatedAt: DateTime.now(),
    );
    await _persist(updated);
    return updated;
  }

  Future<ProRequest> cancel(String requestId) async {
    final current = await getRequest(requestId);
    if (current == null) throw StateError('Request not found');
    final updated = current.copyWith(
      status: ProRequestStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    await _persist(updated);
    return updated;
  }

  Future<ProRequest> complete(String requestId) async {
    final current = await getRequest(requestId);
    if (current == null) throw StateError('Request not found');
    final updated = current.copyWith(
      status: ProRequestStatus.completed,
      updatedAt: DateTime.now(),
    );
    await _persist(updated);
    return updated;
  }

  Future<void> _persist(ProRequest request) async {
    final ref = _userRequestsRef();
    if (ref != null) {
      try {
        final data = request.toMap();
        data['createdAt'] = Timestamp.fromDate(request.createdAt);
        data['updatedAt'] = Timestamp.fromDate(request.updatedAt);
        await ref.doc(request.id).set(data, SetOptions(merge: true));
        // Also keep a local mirror so status screens work offline.
        await _upsertLocal(request);
        return;
      } catch (e, stack) {
        AppLogger.warning(
          'proRequest Firestore write failed; saving locally',
          error: e,
          stackTrace: stack,
        );
      }
    }
    await _upsertLocal(request);
  }

  Future<List<ProRequest>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ProRequest.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, stack) {
      AppLogger.warning('Failed to decode local pro requests', error: e, stackTrace: stack);
      return [];
    }
  }

  Future<void> _upsertLocal(ProRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _loadLocal();
    final next = [
      request,
      ...existing.where((r) => r.id != request.id),
    ];
    await prefs.setString(
      _localKey,
      jsonEncode(next.map((r) => r.toMap()).toList()),
    );
  }
}
