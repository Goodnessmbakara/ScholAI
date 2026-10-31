import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/features/account/domain/platform_role.dart';
import 'package:scholai_app/features/pro/data/models/pro_application.dart';

class ProApplicationService {
  ProApplicationService._();
  static final instance = ProApplicationService._();

  FirebaseFirestore? get _db {
    if (Firebase.apps.isEmpty) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<ProApplication?> mine() async {
    final db = _db;
    final uid = AuthService.instance.uid;
    if (db == null || uid == null) return null;
    final snap = await db.collection('professionalApplications').doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return ProApplication.fromMap(snap.data()!, uid: snap.id);
  }

  Future<void> submit(ProApplication application) async {
    final db = _db;
    if (db == null) throw StateError('Firebase is not ready.');
    final ref = db.collection('professionalApplications').doc(application.uid);
    final existing = await ref.get();
    await ref.set({
      'uid': application.uid,
      'name': application.name,
      'email': application.email,
      'phone': application.phone,
      'credential': application.credential,
      'organization': application.organization,
      'bio': application.bio,
      'areas': application.areas,
      'status': ProApplicationStatus.pending.wire,
      'reviewNote': '',
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<ProApplication>> listAll() async {
    final db = _db;
    if (db == null) return const [];
    final snap = await db.collection('professionalApplications').limit(50).get();
    final list = snap.docs
        .map((doc) => ProApplication.fromMap(doc.data(), uid: doc.id))
        .toList();
    list.sort((a, b) {
      if (a.status == b.status) return a.name.compareTo(b.name);
      if (a.status == ProApplicationStatus.pending) return -1;
      if (b.status == ProApplicationStatus.pending) return 1;
      return a.status.index.compareTo(b.status.index);
    });
    return list;
  }

  Future<void> review({
    required ProApplication application,
    required ProApplicationStatus status,
    String? note,
  }) async {
    final db = _db;
    final reviewer = AuthService.instance.uid;
    if (db == null || reviewer == null) {
      throw StateError('Firebase is not ready.');
    }

    final batch = db.batch();
    final appRef = db.collection('professionalApplications').doc(application.uid);
    batch.set(appRef, {
      'status': status.wire,
      'reviewNote': note ?? '',
      'reviewedBy': reviewer,
      'reviewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (status == ProApplicationStatus.approved) {
      final userRef = db.collection('users').doc(application.uid);
      final userSnap = await userRef.get();
      final current = PlatformRole.fromWire(userSnap.data()?['role'] as String?);
      if (current == PlatformRole.student) {
        batch.set(userRef, {
          'role': PlatformRole.professional.wire,
          'email': application.email,
          'emailLower': application.email.toLowerCase(),
          'displayName': application.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      batch.set(db.collection('professionals').doc(application.uid), {
        'id': application.uid,
        'name': application.name,
        'role': application.credential,
        'specialty': application.areas.join(', '),
        'bio': application.bio,
        'phone': application.phone,
        'availableModes': ['chat', 'call'],
        'active': true,
        'organization': application.organization,
      });
    } else if (status == ProApplicationStatus.rejected) {
      // A previously approved application that is later rejected must not
      // keep the professional in the matching pool.
      batch.set(
        db.collection('professionals').doc(application.uid),
        {'active': false},
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}
