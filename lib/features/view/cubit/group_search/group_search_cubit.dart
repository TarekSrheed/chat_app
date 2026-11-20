import 'package:chat_app/core/helper/helper_function.dart';
import 'package:chat_app/features/data/remote/service/database_service.dart';
import 'package:chat_app/features/view/cubit/group_search/group_search_state.dart';
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

          await _processSnapshotMembers(snapshot);
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
      if (snapshot.docs.isNotEmpty) {
        await _processSnapshotMembers(snapshot);
      }
      emit(GroupSearchSuccess(
          snapshots: [snapshot], joinedStatusMap: Map.from(_joinedStatusMap)));
    } catch (e) {
      emit(GroupSearchError(message: "Error fetching suggested groups"));
    }
  }

  Future<void> _processSnapshotMembers(QuerySnapshot snapshot) async {
    final userId = user?.uid;
    if (userId == null) return;
    final databaseService = DatabaseService(uid: userId);
    final statuses = await Future.wait(snapshot.docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final groupId = data['groupId'] as String? ?? doc.id;
      return MapEntry(groupId, await databaseService.isUserJoined(groupId));
    }));
    _joinedStatusMap.addEntries(statuses);
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
    if (query.trim().isEmpty) {
      emit(GroupSearchSuccess(
        snapshots: const [null],
        searchResults: const [],
        joinedStatusMap: Map.from(_joinedStatusMap),
      ));
      return;
    }
    if (user == null) return;

    emit(GroupSearchLoading());
    try {
      await loadUserData();
      final results = await DatabaseService().searchByName(query);

      final statuses = await Future.wait(results.map((doc) async {
        final data = doc.data();
        final groupId = data['groupId'] as String? ?? doc.id;
        return MapEntry(
          groupId,
          await DatabaseService(uid: user!.uid).isUserJoined(groupId),
        );
      }));
      _joinedStatusMap.addEntries(statuses);

      emit(GroupSearchSuccess(
        snapshots: const [null],
        searchResults: results,
        joinedStatusMap: Map.from(_joinedStatusMap),
      ));
    } catch (e) {
      emit(GroupSearchError(message: "Error searching groups"));
    }
  }
}
