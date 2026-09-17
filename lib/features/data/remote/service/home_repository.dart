import 'package:chat_app/core/helper/helper_function.dart';
import 'package:chat_app/features/data/remote/models/user_model.dart';
import 'package:chat_app/features/data/remote/service/auth_service.dart';
import 'package:chat_app/features/data/remote/service/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeRepository {
  final AuthService _authService;
  final DatabaseService Function(String uid) _databaseServiceBuilder;

  HomeRepository({
    AuthService? authService,
    DatabaseService Function(String uid)? databaseServiceBuilder,
  })  : _authService = authService ?? AuthService(),
        _databaseServiceBuilder =
            databaseServiceBuilder ?? ((uid) => DatabaseService(uid: uid));

  Future<UserDataModel> getUserData() async {
    final email = await HelperFunctions.getUserEmailFromSF() ?? '';
    final userName = await HelperFunctions.getUserNameFromSF() ?? '';
    return UserDataModel(userName: userName, email: email);
  }
   Stream<QuerySnapshot>? getGroupsStream(String uid) {
    return _databaseServiceBuilder(uid).getUserGroups();
  }

   Future<bool> createGroup({
    required String userName,
    required String userId,
    required String groupName,
    required String category,
  }) async {
    try {
      await _databaseServiceBuilder(userId).createGroup(
        userName,
        userId,
        groupName.trim(),
        category,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
   Future<bool> logout() async {
    try {
      await _authService.signOut();
      return true;
    } catch (_) {
      return false;
    }
  }
}