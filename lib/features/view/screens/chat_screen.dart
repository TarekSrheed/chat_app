import 'package:chat_app/features/view/cubit/chat_cubit/chat_cubit.dart';
import 'package:chat_app/features/view/cubit/chat_cubit/chat_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/messeage_tile.dart';
import '../widgets/widgets.dart';
import 'group_info.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.userName,
  });

  final String groupId;
  final String groupName;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubit()..loadChatAndAdmin(groupId),
      child: _ChatScreenBody(
        groupId: groupId,
        groupName: groupName,
        userName: userName,
      ),
    );
  }
}

class _ChatScreenBody extends StatefulWidget {
  const _ChatScreenBody({
    required this.groupId,
    required this.groupName,
    required this.userName,
  });

  final String groupId;
  final String groupName;
  final String userName;

  @override
  State<_ChatScreenBody> createState() => _ChatScreenBodyState();
}

class _ChatScreenBodyState extends State<_ChatScreenBody> {
  final TextEditingController messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void _handleSendMessage(ChatCubit cubit) {
    if (messageController.text.trim().isNotEmpty) {
      cubit.sendMessage(
        groupId: widget.groupId,
        userName: widget.userName,
        message: messageController.text,
      );
      messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final cubit = context.read<ChatCubit>();

    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state is ChatError) {
          showSnackbar(context, Colors.red, state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            foregroundColor: Colors.white,
            title: Text(widget.groupName),
            centerTitle: true,
            backgroundColor: primaryColor,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () {
                  nextScreen(
                    context,
                    GroupInfo(
                      groupId: widget.groupId,
                      groupName: widget.groupName,
                      adminName: cubit.adminName,
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: state is ChatLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMessagesStream(cubit.chatsStream),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: 'Send a message...',
                            filled: true,
                            fillColor: primaryColor.withValues(alpha: 0.45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _handleSendMessage(cubit),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesStream(
      Stream<QuerySnapshot<Map<String, dynamic>>>? chatsStream) {
    if (chatsStream == null) {
      return const Center(child: Text('No messages available.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: chatsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load messages.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages yet. Start the conversation.'),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index].data();
            final message = doc['message']?.toString() ?? '';
            final sender = doc['sender']?.toString() ?? '';

            return MessageTile(
              message: message,
              sender: sender,
              sentByMe:
                  doc['senderId'] == FirebaseAuth.instance.currentUser?.uid,
            );
          },
        );
      },
    );
  }
}
