import 'package:chat_app/features/data/remote/service/home_repository.dart';
import 'package:chat_app/features/data/remote/service/presence_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _homeRepository = HomeRepository();
  
  String userName = '';
  String email = '';
  Stream<QuerySnapshot>? groupsStream;

  HomeCubit() : super(HomeInitial());

  /// تهيئة الحضور المباشر وتحميل البيانات الابتدائية
  Future<void> initHomeScreen() async {
    PresenceService().configureUserPresence();
    await loadInitialData();
  }

  /// تحميل بيانات المستخدم والـ Stream الخاص بالمجموعات
  Future<void> loadInitialData() async {
    emit(HomeLoading());
    try {
      final userData = await _homeRepository.getUserData();
      userName = userData.userName;
      email = userData.email;
      groupsStream = _homeRepository.getGroupsStream(FirebaseAuth.instance.currentUser!.uid);

      emit(HomeLoaded(
        groupsStream: groupsStream,
        userName: userName,
        email: email,
      ));
    } catch (_) {
      emit(HomeError('Unable to load your groups.'));
    }
  }

  /// إنشاء مجموعة جديدة
  Future<void> createGroup({
    required String groupName,
    required String category,
  }) async {
    if (groupName.trim().isEmpty) {
      emit(HomeError('Please enter a group name.'));
      return;
    }

    emit(HomeActionLoading());

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final success = await _homeRepository.createGroup(
        userName: userName,
        userId: userId,
        groupName: groupName,
        category: category,
      );

      if (success) {
        emit(HomeGroupCreatedSuccess());
        await loadInitialData(); // إعادة تحميل المجموعات
      } else {
        emit(HomeError('Unable to create the group.'));
      }
    } catch (e) {
      emit(HomeError('Error creating group: $e'));
    }
  }
}