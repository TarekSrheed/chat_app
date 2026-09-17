import 'package:chat_app/features/data/remote/service/notification_service.dart';
import 'package:chat_app/features/view/screens/auth/login_screen.dart';
import 'package:chat_app/features/view/screens/home_screen.dart';
import 'package:chat_app/core/shared/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'core/helper/helper_function.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initNotification();
print(await FirebaseMessaging.instance.getToken());
  // if (kIsWeb) {
  //   await Firebase.initializeApp(
  //       options: FirebaseOptions(
  //           apiKey: Constants.apiKey,
  //           appId: Constants.appId,
  //           messagingSenderId: Constants.messagingSenderId,
  //           projectId: Constants.projectId));
  // } else {
  //   await Firebase.initializeApp();
  // }

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
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    getUserLoggedInStatus();
  }

  getUserLoggedInStatus() async {
    await HelperFunctions.getUserLoggedInStatus().then((value) {
      if (value != null) {
        setState(() {
          _isSignedIn = value;
        });
      }
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
      home: _isSignedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
