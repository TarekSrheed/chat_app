import 'package:cloud_firestore/cloud_firestore.dart';

abstract class GroupSearchState {}
class GroupSearchInitial extends GroupSearchState {}
class GroupSearchLoading extends GroupSearchState {}
class GroupSearchSuccess extends GroupSearchState {
  final List<QuerySnapshot?> snapshots;
  final Map<String, bool> joinedStatusMap;

  GroupSearchSuccess({required this.snapshots, required this.joinedStatusMap});
}
class GroupSearchError extends GroupSearchState {
  final String message;

  GroupSearchError({required this.message});
}