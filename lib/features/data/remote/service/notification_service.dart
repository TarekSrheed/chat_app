import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // 1. طلب الصلاحية من المستخدم
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    }

    // 2. إعدادات التهيئة للأندرويد
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // تصحيح خطأ: إرسال المعامل كـ Named Parameter باسم initializationSettings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // تصحيح خطأ: إرسال المعامل كـ Named Parameter باسم settings
    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // 3. ربط معالج خلفية Firebase
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. الاستماع للإشعارات عندما يكون التطبيق مفتوحاً (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // تصحيح خطأ: تمرير المعاملات المحددة بالأسماء (id, title, body, notificationDetails)
        _flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 5. حفظ رمز الجهاز FCM Token
    await saveDeviceToken();
  }

  Future<void> saveDeviceToken() async {
    String? token = await _fcm.getToken();
    final user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
      });
    }
  }
  // جلب الـ Access Token التلقائي من ملف Service Account JSON
  static Future<String> _getAccessToken() async {
    final serviceAccountJson =
        await rootBundle.loadString('assets/service_account/service_account.json');

    final accountCredentials =
        ServiceAccountCredentials.fromJson(serviceAccountJson);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(accountCredentials, scopes);
    final accessToken = client.credentials.accessToken.data;
    client.close();

    return accessToken;
  }

  // دالة إرسال الإشعار الحديثة (FCM HTTP v1)
  static Future<void> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final String token = await _getAccessToken();
      
      // استبدل "chatapp-4a9e1" بـ Project ID الخاص بك إن كان مختلفاً
      const String projectId = "chatapp-4a9e1"; 

      await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': {
              'token': targetToken,
              'notification': {
                'title': title,
                'body': body,
              },
              'data': data ?? {},
            },
          },
        ),
      );
    } catch (e) {
      print("Error sending push notification: $e");
    }
  }
}