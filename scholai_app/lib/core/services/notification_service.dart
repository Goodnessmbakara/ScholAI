import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/core/utils/app_logger.dart';
import 'package:scholai_app/core/utils/app_router.dart';
import 'package:scholai_app/firebase_options.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Android notification channel used for FCM + local reminders.
const String kScholaiChannelId = 'scholai_checkin';
const String kScholaiChannelName = 'Daily check-in';
const String kScholaiChannelDesc = 'Gentle reminders to check in with yourself';

const int _dailyCheckInNotificationId = 1001;

/// Top-level background handler — required by firebase_messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.info(
    'FCM background message: ${message.messageId ?? 'no-id'}',
    tag: 'FCM',
  );
}

/// FCM + local notifications for ScholAI.
///
/// Graceful: callers should only invoke [initialize] after Firebase is ready.
/// Failures never crash the app — demo mode continues without push.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;
  StreamSubscription<String>? _tokenRefreshSub;

  bool get isInitialized => _initialized;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();
      // Default to Lagos (primary user base); falls back to UTC if unavailable.
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Lagos'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

      await _initLocalNotifications();
      await _requestPermissions();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _onMessageOpened(initial);
      }

      await _refreshAndPersistToken();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        unawaited(_persistToken(token));
      });

      await scheduleDailyCheckInReminder();

      _initialized = true;
      AppLogger.info('NotificationService ready (token=${_fcmToken != null}).');
    } catch (e, stack) {
      AppLogger.warning(
        'NotificationService init failed — continuing without push',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kScholaiChannelId,
        kScholaiChannelName,
        description: kScholaiChannelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    // iOS / macOS permission prompt via FCM
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Android 13+ POST_NOTIFICATIONS
    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    if (!kIsWeb && Platform.isIOS) {
      // APNs token must exist before some FCM APIs work on iOS.
      final apns = await _messaging.getAPNSToken();
      if (apns == null) {
        AppLogger.info(
          'APNs token unavailable yet — upload APNs key in Firebase Console for iOS push.',
          tag: 'FCM',
        );
      }
    }
  }

  Future<void> _refreshAndPersistToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final apns = await _messaging.getAPNSToken();
        if (apns == null) return;
      }
      final token = await _messaging.getToken();
      _fcmToken = token;
      if (token != null) {
        await _persistToken(token);
        AppLogger.info('FCM token acquired.', tag: 'FCM');
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Could not get FCM token',
        tag: 'FCM',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Stores token under `/users/{uid}/fcmTokens/{tokenId}` when Auth is ready.
  Future<void> _persistToken(String token) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return;

    try {
      // Use a stable doc id from a hash of the token so re-writes update in place.
      final docId = token.length > 24 ? token.substring(0, 24) : token;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(docId)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to persist FCM token',
        tag: 'FCM',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    unawaited(
      _local.show(
        notification.hashCode,
        notification.title ?? 'ScholAI',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            kScholaiChannelId,
            kScholaiChannelName,
            channelDescription: kScholaiChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data['route'] as String? ?? '/home',
      ),
    );
  }

  /// Routes a notification tap may deep-link into. Anything else falls back
  /// to the check-in home tab.
  static const _allowedRoutes = {
    '/home',
    '/journal',
    '/habits',
    '/trends',
    '/crisis',
    '/support',
    '/settings',
    '/live',
    '/my-cases',
  };

  void _openRoute(String? route) {
    final target =
        route != null && _allowedRoutes.contains(route) ? route : '/home';
    // The router may not be attached yet (cold start via notification), so
    // defer navigation to the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        AppRouter.router.go(target);
      } catch (e, stack) {
        AppLogger.warning(
          'Notification navigation failed',
          tag: 'FCM',
          error: e,
          stackTrace: stack,
        );
      }
    });
  }

  void _onMessageOpened(RemoteMessage message) {
    AppLogger.info(
      'Notification opened: ${message.messageId ?? message.data}',
      tag: 'FCM',
    );
    _openRoute(message.data['route'] as String?);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    AppLogger.info(
      'Local notification tap: ${response.payload}',
      tag: 'FCM',
    );
    _openRoute(response.payload);
  }

  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';

  /// Saved reminder time, defaults to 08:00.
  Future<({int hour, int minute})> loadReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      hour: prefs.getInt(_hourKey) ?? 8,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
  }

  /// Persists a new reminder time and reschedules immediately.
  Future<void> saveReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
    await scheduleDailyCheckInReminder(hour: hour, minute: minute);
  }

  /// Schedules a daily local reminder: "Hey. How are you today?"
  /// Falls back to the saved preference when [hour]/[minute] are omitted.
  /// Safe to call repeatedly (replaces prior).
  Future<void> scheduleDailyCheckInReminder({int? hour, int? minute}) async {
    final saved = await loadReminderTime();
    hour ??= saved.hour;
    minute ??= saved.minute;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _local.zonedSchedule(
        _dailyCheckInNotificationId,
        'ScholAI',
        'Hey. How are you today?',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            kScholaiChannelId,
            kScholaiChannelName,
            channelDescription: kScholaiChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/home',
      );

      AppLogger.info(
        'Daily check-in reminder set for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} local.',
        tag: 'FCM',
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Could not schedule daily reminder',
        tag: 'FCM',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> cancelDailyCheckInReminder() async {
    await _local.cancel(_dailyCheckInNotificationId);
  }

  static const _urgeNudgeId = 3;
  static const _urgeNudgeKey = 'urge_nudge_key';

  /// First nudge hour per pattern-card time bucket — inside the window,
  /// early enough to land ahead of the usual urge.
  static const _urgeWindowHour = <String, int>{
    'morning': 8,
    'afternoon': 12,
    'evening': 17,
    'night': 21,
  };

  /// Preemptive urge nudge: once the pattern card knows the usual window,
  /// nudge inside it daily so the interception lands ahead of the urge.
  /// Null [windowLabel] cancels; only reschedules when (window, habit)
  /// changes so build calls are cheap.
  Future<void> syncUrgeWindowNudge(
    String? windowLabel,
    String habitLabel,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = windowLabel == null ? '' : '$windowLabel|$habitLabel';
    if (prefs.getString(_urgeNudgeKey) == key) return;
    await prefs.setString(_urgeNudgeKey, key);
    await _local.cancel(_urgeNudgeId);
    if (windowLabel == null) return;

    final hour = _urgeWindowHour[windowLabel];
    if (hour == null) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, 45);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _local.zonedSchedule(
        _urgeNudgeId,
        'Heads up',
        'Urges usually hit around now for $habitLabel. You know what to do.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            kScholaiChannelId,
            kScholaiChannelName,
            channelDescription: kScholaiChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/habits',
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Could not schedule urge nudge',
        tag: 'FCM',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
