import 'package:chat_app/features/data/remote/models/user_model.dart';
import 'package:chat_app/features/data/remote/service/presence_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/helper/helper_function.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future loginWithUserNameandPassword(String email, String password) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user != null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future registerUserWithEmailandPassword({
    required String fullName,
    required String email,
    required String password,
    required String age,
    required List<String> hobbies,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await DatabaseService(uid: user.uid).savingUserData(
          UserModel(
            uid: user.uid,
            fullName: fullName,
            profilePic: "",
            groups: const [],
            email: email,
            age: age,
            hobbies: hobbies,
          ),
        );
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future signOut() async {
    try {
      await PresenceService().setOffline();
      await HelperFunctions.saveUserLoggedInStatus(false);
      await HelperFunctions.saveUserEmailSF('');
      await HelperFunctions.saveUserNameSF('');
      await firebaseAuth.signOut();
      return true;
    } catch (e) {
      return null;
    }
  }
}
