import 'dart:async';

import 'package:chat_app/features/data/remote/service/database_service.dart';
import 'package:chat_app/features/data/remote/service/notification_service.dart';
import 'package:chat_app/features/view/screens/auth/login_screen.dart';
import 'package:chat_app/features/view/screens/chat_screen.dart';
import 'package:chat_app/features/view/screens/home_screen.dart';
import 'package:chat_app/core/shared/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/helper/helper_function.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Map<String, dynamic>? _pendingNotification;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await NotificationService.instance.initNotification(
      onNotificationTap: _handleNotificationTap,
    );
  } on Exception catch (error) {
    debugPrint(
        'Push notification initialization failed (${error.runtimeType}).');
  }
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user == null) return;
    unawaited(_migrateLegacyData(user.uid));
    unawaited(_openPendingNotification());
  });

  // ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  // ZegoUIKit().initLog().then((value) {
  //   ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
  //     [ZegoUIKitSignalingPlugin()],
  //   );

  //   runApp(MyApp(navigatorKey: navigatorKey));
  // });
  runApp(MyApp(navigatorKey: navigatorKey));
  // runApp(MyApp());
}

Future<void> _migrateLegacyData(String uid) async {
  try {
    await DatabaseService(uid: uid).migrateLegacyUserData();
  } on Exception catch (error) {
    debugPrint('Legacy profile migration failed (${error.runtimeType}).');
  }
}

Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
  final groupId = data['groupId'];
  if (groupId is! String || groupId.isEmpty || groupId.length > 150) return;
  _pendingNotification = Map<String, dynamic>.from(data);
  await _openPendingNotification();
}

Future<void> _openPendingNotification() async {
  final data = _pendingNotification;
  final user = FirebaseAuth.instance.currentUser;
  if (data == null || user == null || navigatorKey.currentState == null) return;
  _pendingNotification = null;

  final groupId = data['groupId'] as String;
  try {
    var group = await FirebaseFirestore.instance
        .collection('groupDirectory')
        .doc(groupId)
        .get();
    var groupName = group.data()?['groupName'] as String? ?? '';
    if (groupName.isEmpty) {
      group = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();
      groupName = group.data()?['groupName'] as String? ?? '';
    }

    final userName =
        await HelperFunctions.getUserNameFromSF() ?? user.displayName ?? 'User';
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          groupId: groupId,
          groupName: groupName.isEmpty ? 'Group' : groupName,
          userName: userName,
        ),
      ),
    );
  } on FirebaseException catch (error) {
    debugPrint('Unable to open the notification destination (${error.code}).');
  } on Exception catch (error) {
    debugPrint(
      'Unable to open the notification destination (${error.runtimeType}).',
    );
  }
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const MyApp({
    Key? key,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openPendingNotification());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: widget.navigatorKey,
      theme: ThemeData(
          appBarTheme: AppBarTheme(
            foregroundColor: Colors.white,
            backgroundColor: Constants().primaryColor,
            elevation: 0,
            titleTextStyle: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            centerTitle: true,
          ),
          textTheme: ThemeData.light().textTheme.copyWith(
                headlineMedium: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Cairo',
                    color: Colors.blue,
                    fontWeight: FontWeight.bold),
                headlineLarge: const TextStyle(
                    fontSize: 26,
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
          primaryColor: Constants().primaryColor,
          scaffoldBackgroundColor: Colors.white),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data == null
              ? const LoginScreen()
              : const HomeScreen();
        },
      ),
    );
  }
}
