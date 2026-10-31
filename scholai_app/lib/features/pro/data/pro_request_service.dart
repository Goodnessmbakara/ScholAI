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

  CollectionReference<Map<String, dynamic>>? _requestsRefFor(String? uid) {
    final db = _db;
    if (db == null || uid == null || uid.isEmpty) return null;
    return db.collection('users').doc(uid).collection('proRequests');
  }

  CollectionReference<Map<String, dynamic>>? _userRequestsRef() =>
      _requestsRefFor(AuthService.instance.uid);

  /// Approved professionals written by an admin. Empty until someone is approved.
  /// Only active pros are returned — they feed matching and assignment.
  Future<List<Professional>> listProfessionals() async {
    return (await _listProfessionals())
        .where((pro) => pro.active)
        .toList();
  }

  /// Admin view — includes deactivated pros so the roster can be managed.
  Future<List<Professional>> listAllProfessionals() => _listProfessionals();

  Future<List<Professional>> _listProfessionals() async {
    final db = _db;
    if (db == null) return const [];
    try {
      final snap = await db.collection('professionals').get();
      return snap.docs
          .map((d) => Professional.fromMap(d.data(), id: d.id))
          .where((pro) => pro.id.isNotEmpty)
          .toList();
    } catch (e, stack) {
      AppLogger.warning(
        'Professionals Firestore read failed',
        error: e,
        stackTrace: stack,
      );
      return const [];
    }
  }

  /// Pause or resume a professional — inactive pros are skipped by
  /// auto-match and the admin assignment dropdown.
  Future<void> setProfessionalActive(String professionalId, bool active) async {
    final db = _db;
    if (db == null) throw StateError('Firebase is not ready.');
    await db.collection('professionals').doc(professionalId).set(
      {'active': active},
      SetOptions(merge: true),
    );
  }

  Future<List<ProRequest>> listQueue() async {
    final db = _db;
    if (db == null) return const [];
    final snap = await db.collectionGroup('proRequests').limit(40).get();
    return _fromQueueDocs(snap.docs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Requests matched to the signed-in professional. `professionalId` on the
  /// request is the pro's Firebase uid — the `professionals` doc id.
  Future<List<ProRequest>> listMyCases() async {
    final db = _db;
    final uid = AuthService.instance.uid;
    if (db == null || uid == null) return const [];
    final snap = await db
        .collectionGroup('proRequests')
        .where('professionalId', isEqualTo: uid)
        .limit(40)
        .get();
    return _fromQueueDocs(snap.docs)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<ProRequest> _fromQueueDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) {
          final data = doc.data();
          final parentUid = doc.reference.parent.parent?.id;
          return ProRequest.fromMap(
            {...data, if (data['userId'] == null && parentUid != null) 'userId': parentUid},
            id: doc.id,
          );
        })
        .toList();
  }

  Future<void> assignProfessional({
    required ProRequest request,
    required Professional professional,
  }) async {
    final db = _db;
    final uid = request.userId;
    if (db == null || uid == null || uid.isEmpty) {
      throw StateError('This request has no student account to update.');
    }
    await db.collection('users').doc(uid).collection('proRequests').doc(request.id).update({
      'status': ProRequestStatus.matched.wire,
      'professionalId': professional.id,
      'professionalName': professional.name,
      'professionalRole': professional.role,
      if (professional.phone != null) 'professionalPhone': professional.phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    return _localRequest(id);
  }

  /// Live updates for one request. Emits from Firestore when available so a
  /// match or message written by staff appears without a manual refresh;
  /// falls back to the local copy for offline/demo requests.
  ///
  /// Staff pass [forUid] — the student's user id — to watch a request that
  /// lives under someone else's account. The local mirror only applies to
  /// the caller's own requests.
  Stream<ProRequest?> watchRequest(String id, {String? forUid}) async* {
    final ref = _requestsRefFor(forUid ?? AuthService.instance.uid);
    if (ref == null) {
      yield forUid == null ? await getRequest(id) : null;
      return;
    }
    try {
      await for (final doc in ref.doc(id).snapshots()) {
        if (doc.exists && doc.data() != null) {
          yield ProRequest.fromMap(doc.data()!, id: doc.id);
        } else {
          yield forUid == null ? await _localRequest(id) : null;
        }
      }
    } catch (e, stack) {
      AppLogger.warning(
        'proRequest watch failed; using local copy',
        error: e,
        stackTrace: stack,
      );
      yield forUid == null ? await _localRequest(id) : null;
    }
  }

  Future<ProRequest?> _localRequest(String id) async {
    final local = await _loadLocal();
    for (final r in local) {
      if (r.id == id) return r;
    }
    return null;
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
              '${request.topic.toLowerCase()}. This is an automated intro '
              'sent on my behalf — I\'ll see your messages and reply when '
              'I\'m next in the app. Reminder: this session is not anonymous.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
    await _persist(matched);
    return matched;
  }

  Map<String, dynamic> _messageToMap(ChatMessage m) => {
        'text': m.text,
        'isUser': m.isUser,
        if (m.timestamp != null) 'at': m.timestamp!.toIso8601String(),
      };

  /// Writes only [fields] to the caller's request doc, then mirrors
  /// [localDoc] into the local cache. Field-scoped writes + arrayUnion keep
  /// a staff/pro message that lands between read and write from being
  /// clobbered by a full-document overwrite.
  Future<void> _persistFields(
    String requestId,
    Map<String, dynamic> fields, {
    required ProRequest localDoc,
  }) async {
    final ref = _userRequestsRef();
    if (ref != null) {
      try {
        await ref.doc(requestId).set(fields, SetOptions(merge: true));
        await _upsertLocal(localDoc);
        return;
      } catch (e, stack) {
        AppLogger.warning(
          'proRequest remote update failed; saving locally',
          error: e,
          stackTrace: stack,
        );
      }
    }
    await _upsertLocal(localDoc);
  }

  Future<ProRequest> scheduleChat(String requestId) async {
    final current = await getRequest(requestId);
    if (current == null) throw StateError('Request not found');
    final updated = current.copyWith(
      status: ProRequestStatus.chatScheduled,
      updatedAt: DateTime.now(),
    );
    await _persistFields(requestId, {
      'status': ProRequestStatus.chatScheduled.wire,
      'updatedAt': FieldValue.serverTimestamp(),
    }, localDoc: updated);
    return updated;
  }

  /// Marks call scheduled. Caller may launch `tel:` when [professionalPhone] exists.
  Future<ProRequest> requestCall(String requestId) async {
    final current = await getRequest(requestId);
    if (current == null) throw StateError('Request not found');
    final message = ChatMessage(
      text: current.professionalPhone != null
          ? 'Call requested. You can dial the volunteer now, or wait for a callback in your time window (${current.timeWindow}).'
          : 'Call requested. ${current.professionalName ?? 'Your volunteer'} will call you back during ${current.timeWindow}.',
      isUser: false,
      timestamp: DateTime.now(),
    );
    final updated = current.copyWith(
      status: ProRequestStatus.callScheduled,
      preferredMode: ProPreferredMode.call,
      updatedAt: DateTime.now(),
      messages: [...current.messages, message],
    );
    await _persistFields(requestId, {
      'status': ProRequestStatus.callScheduled.wire,
      'preferredMode': ProPreferredMode.call.wire,
      'messages': FieldValue.arrayUnion([_messageToMap(message)]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, localDoc: updated);
    return updated;
  }

  Future<ProRequest> appendMessage(String requestId, String text, {required bool isUser}) async {
    final current = await getRequest(requestId);
    if (current == null) throw StateError('Request not found');

    if (isUser && CrisisDetection.containsCrisisSignal(text)) {
      throw const CrisisDivertException();
    }

    final message =
        ChatMessage(text: text, isUser: isUser, timestamp: DateTime.now());

    var status = current.status;
    if (status == ProRequestStatus.matched || status == ProRequestStatus.pending) {
      status = ProRequestStatus.chatScheduled;
    }

    final updated = current.copyWith(
      messages: [...current.messages, message],
      status: status,
      updatedAt: DateTime.now(),
    );
    await _persistFields(requestId, {
      'messages': FieldValue.arrayUnion([_messageToMap(message)]),
      'status': status.wire,
      'updatedAt': FieldValue.serverTimestamp(),
    }, localDoc: updated);
    return updated;
  }

  /// Staff reply: appends a message to a request under another user's
  /// account (`users/{userId}/proRequests/{requestId}`). Firestore rules
  /// allow admin updates only — non-admins get a permission error, which
  /// callers should surface as a snackbar.
  Future<ProRequest> appendStaffMessage({
    required String userId,
    required String requestId,
    required String text,
  }) async {
    final ref = _requestsRefFor(userId);
    if (ref == null) {
      throw StateError('Staff replies need a cloud-backed student account.');
    }
    final doc = await ref.doc(requestId).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Request not found.');
    }
    final current = ProRequest.fromMap(doc.data()!, id: doc.id);

    var status = current.status;
    if (status == ProRequestStatus.matched ||
        status == ProRequestStatus.pending) {
      status = ProRequestStatus.chatScheduled;
    }

    final message = ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );

    final updated = current.copyWith(
      messages: [...current.messages, message],
      status: status,
      updatedAt: DateTime.now(),
    );

    // arrayUnion so a student message landing concurrently is not lost.
    await ref.doc(requestId).set({
      'messages': FieldValue.arrayUnion([_messageToMap(message)]),
      'status': status.wire,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return updated;
  }

  Future<ProRequest> cancel(String requestId) =>
      _setStatus(requestId, ProRequestStatus.cancelled);

  Future<ProRequest> complete(String requestId) =>
      _setStatus(requestId, ProRequestStatus.completed);

  Future<ProRequest> _setStatus(
    String requestId,
    ProRequestStatus status,
  ) async {
    final current = await getRequest(requestId);
    if (current == null) throw StateError('Request not found');
    final updated = current.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    await _persistFields(requestId, {
      'status': status.wire,
      'updatedAt': FieldValue.serverTimestamp(),
    }, localDoc: updated);
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
