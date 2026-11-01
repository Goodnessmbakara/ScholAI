import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/core/utils/app_logger.dart';
import 'package:scholai_app/features/account/domain/platform_role.dart';

class PlatformProfile {
  final String uid;
  final PlatformRole role;
  final String email;
  final String displayName;
  final String avatarEmoji;

  const PlatformProfile({
    required this.uid,
    required this.role,
    required this.email,
    required this.displayName,
    this.avatarEmoji = '',
  });

  bool get canManagePlatform =>
      role.canManagePlatform || isBootstrapSuperAdmin(email);

  bool get canAssignRoles => role.canAssignRoles || isBootstrapSuperAdmin(email);
}

class AccountService {
  AccountService._();
  static final instance = AccountService._();

  PlatformProfile? profile;

  FirebaseFirestore? get _db {
    if (Firebase.apps.isEmpty) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<PlatformProfile?> ensureProfile() async {
    final db = _db;
    final user = FirebaseAuth.instance.currentUser;
    if (db == null || user == null) return profile;

    final email = (user.email ?? AuthService.instance.linkedEmail ?? '').trim();
    final name = (user.displayName ?? '').trim();
    final bootstrap = isBootstrapSuperAdmin(email);
    final ref = db.collection('users').doc(user.uid);

    try {
      final snap = await ref.get();
      final existing = snap.data();
      final current = PlatformRole.fromWire(existing?['role'] as String?);
      final role = bootstrap ? PlatformRole.superAdmin : current;
      // A name the user set in-app wins over the Google account name, which
      // only seeds the profile on first creation.
      final storedName = (existing?['displayName'] as String? ?? '').trim();
      final displayName = storedName.isNotEmpty
          ? storedName
          : (name.isNotEmpty ? name : await _localName());
      final avatarEmoji =
          (existing?['avatarEmoji'] as String? ?? '').isNotEmpty
              ? existing!['avatarEmoji'] as String
              : await _localAvatar();
      final next = PlatformProfile(
        uid: user.uid,
        role: snap.exists ? role : (bootstrap ? PlatformRole.superAdmin : PlatformRole.student),
        email: email,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
      );

      final shouldWrite = !snap.exists ||
          existing?['role'] != next.role.wire ||
          (email.isNotEmpty && existing?['email'] != email) ||
          (storedName.isEmpty && displayName.isNotEmpty);
      if (shouldWrite) {
        await ref.set({
          'role': next.role.wire,
          'email': email,
          'emailLower': email.toLowerCase(),
          'displayName': displayName,
          if (avatarEmoji.isNotEmpty) 'avatarEmoji': avatarEmoji,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      profile = next;
      return next;
    } catch (e, stack) {
      AppLogger.warning('Could not sync account profile', error: e, stackTrace: stack);
      profile = PlatformProfile(
        uid: user.uid,
        role: bootstrap ? PlatformRole.superAdmin : PlatformRole.student,
        email: email,
        displayName: name.isNotEmpty ? name : await _localName(),
        avatarEmoji: await _localAvatar(),
      );
      return profile;
    }
  }

  static const _nameKey = 'profile_display_name';
  static const _avatarKey = 'profile_avatar_emoji';
  static const _facultyKey = 'profile_faculty';
  static const _yearKey = 'profile_year_of_study';

  Future<String> _localName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey)?.trim() ?? '';
  }

  Future<String> _localAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarKey)?.trim() ?? '';
  }

  /// Edit the student's display name and/or avatar emoji.
  ///
  /// Writes to `users/{uid}` when the cloud is available and mirrors to
  /// SharedPreferences so anonymous/offline profiles still customize.
  Future<PlatformProfile?> updateProfile({
    String? displayName,
    String? avatarEmoji,
    String? faculty,
    String? yearOfStudy,
  }) async {
    final name = displayName?.trim();
    final emoji = avatarEmoji?.trim();
    final fac = faculty?.trim();
    final year = yearOfStudy?.trim();
    if ((name == null || name.isEmpty) &&
        (emoji == null || emoji.isEmpty) &&
        (fac == null || fac.isEmpty) &&
        (year == null || year.isEmpty)) {
      return profile;
    }

    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.isNotEmpty) {
      await prefs.setString(_nameKey, name);
    }
    if (emoji != null && emoji.isNotEmpty) {
      await prefs.setString(_avatarKey, emoji);
    }
    if (fac != null && fac.isNotEmpty) await prefs.setString(_facultyKey, fac);
    if (year != null && year.isNotEmpty) await prefs.setString(_yearKey, year);

    final user = FirebaseAuth.instance.currentUser;
    final db = _db;
    if (db != null && user != null) {
      try {
        final data = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (name != null && name.isNotEmpty) data['displayName'] = name;
        if (emoji != null && emoji.isNotEmpty) data['avatarEmoji'] = emoji;
        if (fac != null && fac.isNotEmpty) data['faculty'] = fac;
        if (year != null && year.isNotEmpty) data['yearOfStudy'] = year;
        await db.collection('users').doc(user.uid).set(
              data,
              SetOptions(merge: true),
            );
        if (name != null && name.isNotEmpty) {
          await user.updateDisplayName(name);
        }
      } catch (e, stack) {
        AppLogger.warning('Could not save profile', error: e, stackTrace: stack);
      }
    }

    final current = profile;
    profile = PlatformProfile(
      uid: user?.uid ?? current?.uid ?? '',
      role: current?.role ?? PlatformRole.student,
      email: current?.email ?? '',
      displayName:
          name != null && name.isNotEmpty ? name : (current?.displayName ?? ''),
      avatarEmoji: emoji != null && emoji.isNotEmpty
          ? emoji
          : (current?.avatarEmoji ?? ''),
    );
    return profile;
  }

  Future<List<PlatformProfile>> searchUsers(String query) async {
    final db = _db;
    if (db == null) return const [];
    final q = query.trim().toLowerCase();
    Query<Map<String, dynamic>> users = db.collection('users');
    if (q.isNotEmpty) {
      users = users
          .where('emailLower', isGreaterThanOrEqualTo: q)
          .where('emailLower', isLessThan: '$q\uf8ff');
    }
    final snap = await users.limit(40).get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return PlatformProfile(
        uid: doc.id,
        role: PlatformRole.fromWire(data['role'] as String?),
        email: data['email'] as String? ?? '',
        displayName: data['displayName'] as String? ?? '',
      );
    }).toList();
  }

  Future<void> setRole({
    required String uid,
    required PlatformRole role,
  }) async {
    final db = _db;
    if (db == null) {
      throw StateError('Firebase is not ready.');
    }
    await db.collection('users').doc(uid).set({
      'role': role.wire,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
