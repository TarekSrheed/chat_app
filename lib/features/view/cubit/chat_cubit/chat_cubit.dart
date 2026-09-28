// import 'package:chat_app/features/data/remote/service/chat_screen_controller.dart';
// import 'package:chat_app/features/view/cubit/chat_cubit/chat_state.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class ChatCubit extends Cubit<ChatState> {
//   final ChatScreenRepository _controller = ChatScreenRepository();

//   ChatCubit() : super(ChatInitial());

// //  Future<void> initHomeScreen() async {
// //     PresenceService().configureUserPresence();
// //     await loadChatAndAdmin();
// //   }

//   Stream<QuerySnapshot<Map<String, dynamic>>>? chats;

//   String admin = '';

//   Future<void> loadChatAndAdmin(String groupId) async {
//     emit(ChatLoading());
//     try {
//       final data = await _controller.loadChatAndAdmin(groupId);
//       chats = data.chats;
//       admin = data.admin;
//       emit(ChatAndAdminLoaded(chatStream: chats, adminName: admin));
//     } catch (_) {
//       emit(ChatError('Unable to load your chats.'));
//     }
//   }

//   /// تحميل بيانات المستخدم والـ Stream الخاص بالمجموعات

//   Future<void> sendMessage({
//     required String groupId,
//     required String userName,
//     required String message,
//   }) async {
//     emit(ChatLoading());
//     try {
//       final success = await _controller.sendMessage(
//         groupId: groupId,
//         userName: userName,
//         message: message,
//       );
//       if (success) {
//         emit(SendMessageSuccess());
//       }
//     } catch (e) {
//       emit(ChatError('Unable to send message.'));
//     }
//   }
// }
import 'package:chat_app/features/view/repository/chat_repository.dart';
import 'package:chat_app/features/view/cubit/chat_cubit/chat_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;

  Stream<QuerySnapshot<Map<String, dynamic>>>? chatsStream;
  String adminName = '';

  ChatCubit({ChatRepository? chatRepository})
      : _chatRepository = chatRepository ?? ChatRepository(),
        super(ChatInitial());

  /// تحميل البث المباشر للرسائل واسم الأدمن
  Future<void> loadChatAndAdmin(String groupId) async {
    emit(ChatLoading());
    try {
      chatsStream = _chatRepository.getChats(groupId);
      adminName = await _chatRepository.getGroupAdmin(groupId);

      emit(ChatLoaded(
        chatStream: chatsStream,
        adminName: adminName,
      ));
    } catch (_) {
      emit(ChatError('Unable to load messages.'));
    }
  }

  /// إرسال رسالة
  Future<void> sendMessage({
    required String groupId,
    required String userName,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;

    try {
      await _chatRepository.sendMessage(
        groupId: groupId,
        userName: userName,
        message: message,
      );
      emit(ChatMessageSentSuccess());
    } catch (_) {
      emit(ChatError('Failed to send message.'));
    }
  }
}
