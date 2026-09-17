import 'package:cloud_firestore/cloud_firestore.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final Stream<QuerySnapshot>? groupsStream;
  final String userName;
  final String email;

  HomeLoaded({
    required this.groupsStream,
    required this.userName,
    required this.email,
  });
}

class HomeActionLoading extends HomeState {}

class HomeGroupCreatedSuccess extends HomeState {}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}