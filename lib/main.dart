import 'package:chat_app/screens/auth/login_screen.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/shared/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'helper/helper_function.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: Constants.apiKey,
            appId: Constants.appId,
            messagingSenderId: Constants.messagingSenderId,
            projectId: Constants.projectId));
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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
      theme: ThemeData(
          textTheme: ThemeData.light().textTheme.copyWith(
                headline5: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Cairo',
                    color: Colors.blue,
                    fontWeight: FontWeight.bold),
                headline6: const TextStyle(
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
