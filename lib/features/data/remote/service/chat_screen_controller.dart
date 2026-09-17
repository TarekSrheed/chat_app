import 'package:cloud_firestore/cloud_firestore.dart';

import 'database_service.dart';

class ChatScreenViewModel {
  const ChatScreenViewModel({
    required this.chats,
    required this.admin,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>>? chats;
  final String admin;
}

class ChatScreenController {
  Future<ChatScreenViewModel> loadChatAndAdmin(String groupId) async {
    final chats = DatabaseService().getChats(groupId);
    final admin = await DatabaseService().getGroupAdmin(groupId);

    return ChatScreenViewModel(chats: chats, admin: admin);
  }

  Future<bool> sendMessage({
    required String groupId,
    required String userName,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      return false;
    }

    try {
      final chatMessageMap = <String, dynamic>{
        'message': message.trim(),
        'sender': userName,
        'time': DateTime.now().millisecondsSinceEpoch,
      };

      DatabaseService().sendMessage(groupId, chatMessageMap);
      return true;
    } catch (_) {
      return false;
    }
  }
}
