import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:chat_app/core/constants/api_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:chat_app/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final CollectionReference<Map<String, dynamic>> _tokenCollection =
      FirebaseFirestore.instance.collection('fcmTokens');

  Future<void> Function(Map<String, dynamic>)? _onNotificationTap;
  bool _initialized = false;

  Future<void> initNotification({
    required Future<void> Function(Map<String, dynamic>) onNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    const androidChannel = AndroidNotificationChannel(
      'group_chat_messages',
      'Group chat messages',
      description: 'Notifications for new group chat messages',
      importance: Importance.high,
    );
    final androidNotifications =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidNotifications?.createNotificationChannel(androidChannel);

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleLocalNotificationPayload(response.payload);
      },
    );
    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleLocalNotificationPayload(
        launchDetails?.notificationResponse?.payload,
      );
    }

    FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundNotification(message));
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_openNotification(message.data));
    });
    _fcm.onTokenRefresh.listen(
      (token) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) unawaited(_registerToken(user.uid, token));
      },
      onError: (Object error) {
        debugPrint('FCM token refresh listener failed (${error.runtimeType}).');
      },
    );

    FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (user != null) unawaited(_requestPermissionAndRegister(user));
      },
      onError: (Object error) {
        debugPrint(
            'FCM authentication listener failed (${error.runtimeType}).');
      },
    );

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      await _openNotification(initialMessage.data);
    }
    _initialized = true;
  }

  Future<void> saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _fcm.getToken().timeout(const Duration(seconds: 10));
      if (token != null && token.isNotEmpty) {
        await _registerToken(user.uid, token);
      }
    } on Exception catch (error) {
      debugPrint('Unable to register FCM token (${error.runtimeType}).');
    }
  }

  Future<void> removeCurrentDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _fcm.getToken().timeout(const Duration(seconds: 5));
      if (token == null || token.isEmpty) return;
      await _tokenCollection
          .doc(_tokenDocumentId(user.uid, token))
          .delete()
          .timeout(const Duration(seconds: 5));
      await _fcm.deleteToken();
    } on Exception catch (error) {
      debugPrint(
          'Unable to remove the current FCM token (${error.runtimeType}).');
    }
  }

  Future<void> sendMessageNotification({
    required String groupId,
    required String messageId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.notificationApi);
      if (uri.scheme != 'https' && uri.host != 'localhost') {
        debugPrint('Push API URL must use HTTPS.');
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        debugPrint('Unable to obtain a Firebase ID token for push delivery.');
        return;
      }

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'groupId': groupId,
              'messageId': messageId,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Push API returned HTTP ${response.statusCode}.');
      }
    } on Exception catch (error) {
      debugPrint(
        'Push delivery request failed after the message was saved '
        '(${error.runtimeType}).',
      );
    } catch (error) {
      debugPrint(
        'Push delivery request failed after the message was saved '
        '(${error.runtimeType}).',
      );
    }
  }

  Future<void> _requestPermissionAndRegister(User user) async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await _fcm.getToken().timeout(const Duration(seconds: 10));
      if (token != null && token.isNotEmpty) {
        await _registerToken(user.uid, token);
      }
    } on Exception catch (error) {
      debugPrint(
        'Unable to request notification permission (${error.runtimeType}).',
      );
    }
  }

  Future<void> _registerToken(String userId, String token) async {
    try {
      await _tokenCollection.doc(_tokenDocumentId(userId, token)).set({
        'uid': userId,
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('PUSH_DEBUG: FCM token saved successfully');
    } on FirebaseException catch (error) {
      debugPrint('FCM token registration was rejected (${error.code}).');
    } on Exception catch (error) {
      debugPrint('Unable to register FCM token (${error.runtimeType}).');
    }
  }

  String _tokenDocumentId(String userId, String token) =>
      sha256.convert(utf8.encode('$userId:$token')).toString();

  void _handleLocalNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        unawaited(_openNotification(decoded));
      }
    } on FormatException {
      debugPrint('Ignoring an invalid local notification payload.');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    try {
      await _localNotifications.show(
        id: message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'group_chat_messages',
            'Group chat messages',
            channelDescription: 'Notifications for new group chat messages',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    } on Exception catch (error) {
      debugPrint(
          'Unable to show a foreground notification (${error.runtimeType}).');
    }
  }

  Future<void> _openNotification(Map<String, dynamic> data) async {
    final groupId = data['groupId'];
    if (groupId is! String || groupId.isEmpty || groupId.length > 150) return;
    final callback = _onNotificationTap;
    if (callback != null) await callback(data);
  }
}
