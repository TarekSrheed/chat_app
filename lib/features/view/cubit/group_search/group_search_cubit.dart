import 'package:chat_app/core/helper/helper_function.dart';
import 'package:chat_app/features/data/remote/service/database_service.dart';
import 'package:chat_app/features/view/cubit/group_search/group_search_state.dart';
import 'package:chat_app/features/view/widgets/group_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupSearchCubit extends Cubit<GroupSearchState> {
  GroupSearchCubit() : super(GroupSearchInitial());

  String userName = "";
  String email = "";
  User? user = FirebaseAuth.instance.currentUser;
  final Map<String, bool> _joinedStatusMap = {};

  Future<void> loadUserData() async {
    userName = await HelperFunctions.getUserNameFromSF() ?? "";
    email = await HelperFunctions.getUserEmailFromSF() ?? "";
    user = FirebaseAuth.instance.currentUser;
  }

  Future<void> fetchSuggestedGroups() async {
    emit(GroupSearchLoading());
    try {
      await loadUserData();
      final List<String> userHobbies = await HelperFunctions.getUserHobbiesSF();
      List<QuerySnapshot?> snapshots = [null, null, null];
      for (int i = 0; i < userHobbies.length; i++) {
        if (userHobbies[i].isNotEmpty) {
          final snapshot =
              await DatabaseService().searchBycategory(userHobbies[i]);
          snapshots[i] = snapshot;
          if (snapshot != null) {
            _processSnapshotMembers(snapshot);
          }
        }
      }

      emit(GroupSearchSuccess(
          snapshots: snapshots, joinedStatusMap: Map.from(_joinedStatusMap)));
    } catch (e) {
      emit(GroupSearchError(message: "Error fetching suggested groups"));
    }
  }

  Future<void> fetchGroupsbyCategory(String category) async {
    if (category.trim().isEmpty || user == null) return;

    emit(GroupSearchLoading());
    try {
      await loadUserData();
      final snapshot = await DatabaseService().searchBycategory(category);
      if (snapshot != null && snapshot.docs.isNotEmpty) {
        _processSnapshotMembers(snapshot);
      }
      emit(GroupSearchSuccess(
          snapshots: [snapshot], joinedStatusMap: Map.from(_joinedStatusMap)));
    } catch (e) {
      emit(GroupSearchError(message: "Error fetching suggested groups"));
    }
  }

  void _processSnapshotMembers(QuerySnapshot snapshot) {
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final groupId = data['groupId'];
      final List members = data['members'] ?? [];

      _joinedStatusMap[groupId] = GroupUtils.isUserJoined(
        members,
        user?.uid ?? "",
        userName,
      );
    }
  }

  /// التبديل الفوري بين الانضمام والمغادرة (Optimistic Update)
  Future<bool> toggleGroupJoin(String groupId, String groupName) async {
    if (user == null) return false;

    final currentlyJoined = _joinedStatusMap[groupId] ?? false;
    final newState = !currentlyJoined;

    // تحديث الحالة محلياً
    _joinedStatusMap[groupId] = newState;

    if (state is GroupSearchSuccess) {
      final currentSuccess = state as GroupSearchSuccess;
      emit(GroupSearchSuccess(
        snapshots: currentSuccess.snapshots,
        joinedStatusMap: Map.from(_joinedStatusMap),
      ));
    }

    try {
      await DatabaseService(uid: user!.uid)
          .toggleGroupJoin(groupId, userName, groupName);
      return newState; // إرجاع الحالة الجديدة لعرض الـ SnackBar
    } catch (e) {
      // تدارك الخطأ وإعادة الحالة القديمة
      _joinedStatusMap[groupId] = currentlyJoined;
      if (state is GroupSearchSuccess) {
        final currentSuccess = state as GroupSearchSuccess;
        emit(GroupSearchSuccess(
          snapshots: currentSuccess.snapshots,
          joinedStatusMap: Map.from(_joinedStatusMap),
        ));
      }
      rethrow;
    }
  }

  Future<void> searchGroupByName(String query) async {
    if (query.trim().isEmpty || user == null) return;

    emit(GroupSearchLoading());
    try {
      await loadUserData();
      final snapshot = await DatabaseService().searchByName(query);

      if (snapshot != null && snapshot.docs.isNotEmpty) {
        _processSnapshotMembers(snapshot);
      }

      emit(GroupSearchSuccess(
        snapshots: [snapshot],
        joinedStatusMap: Map.from(_joinedStatusMap),
      ));
    } catch (e) {
      emit(GroupSearchError(message: "Error searching groups"));
    }
  }
}
