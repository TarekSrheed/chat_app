import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final Stream<QuerySnapshot<Map<String, dynamic>>>? chatStream;
  final String adminName;

  ChatLoaded({
    required this.chatStream,
    required this.adminName,
  });
}

class ChatActionLoading extends ChatState {}

class ChatMessageSentSuccess extends ChatState {}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}
