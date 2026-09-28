// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'database_service.dart';

// class ChatScreenViewModel {
//   const ChatScreenViewModel({
//     required this.chats,
//     required this.admin,
//   });

//   final Stream<QuerySnapshot<Map<String, dynamic>>>? chats;
//   final String admin;
// }

// class ChatScreenController {
//   Future<ChatScreenViewModel> loadChatAndAdmin(String groupId) async {
//     final chats = DatabaseService().getChats(groupId);
//     final admin = await DatabaseService().getGroupAdmin(groupId);

//     return ChatScreenViewModel(chats: chats, admin: admin);
//   }

//   Future<bool> sendMessage({
//     required String groupId,
//     required String userName,
//     required String message,
//   }) async {
//     if (message.trim().isEmpty) {
//       return false;
//     }

//     try {
//       final chatMessageMap = <String, dynamic>{
//         'message': message.trim(),
//         'sender': userName,
//         'time': DateTime.now().millisecondsSinceEpoch,
//       };

//       DatabaseService().sendMessage(groupId, chatMessageMap);
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/remote/service/database_service.dart';

class ChatRepository {
  final DatabaseService _databaseService;

  ChatRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  /// جلب البث المباشر للرسائل
  Stream<QuerySnapshot<Map<String, dynamic>>>? getChats(String groupId) {
    return _databaseService.getChats(groupId);
  }

  /// جلب مسؤول المجموعة
  Future<String> getGroupAdmin(String groupId) async {
    return await _databaseService.getGroupAdmin(groupId);
  }

  /// إرسال رسالة جديدة
  Future<void> sendMessage({
    required String groupId,
    required String userName,
    required String message,
  }) async {
    final chatMessageMap = <String, dynamic>{
      'message': message.trim(),
      'sender': userName,
      'time': DateTime.now().millisecondsSinceEpoch,
    };

    await _databaseService.sendMessage(groupId, chatMessageMap);
  }
}
