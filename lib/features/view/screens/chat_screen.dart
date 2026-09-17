import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/remote/service/chat_screen_controller.dart';
import '../widgets/messeage_tile.dart';
import '../widgets/widgets.dart';
import 'group_info.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen(
      {super.key,
      required this.groupId,
      required this.groupName,
      required this.userName});

  final String groupId;
  final String groupName;
  final String userName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatScreenController _controller = ChatScreenController();
  final TextEditingController messageController = TextEditingController();
  Stream<QuerySnapshot<Map<String, dynamic>>>? chats;
  String admin = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatAndAdmin();
  }

  Future<void> _loadChatAndAdmin() async {
    setState(() => isLoading = true);
    try {
      final viewModel = await _controller.loadChatAndAdmin(widget.groupId);

      if (!mounted) return;
      setState(() {
        chats = viewModel.chats;
        admin = viewModel.admin;
      });
    } catch (_) {
      if (!mounted) return;
      showSnackbar(context, Colors.red, 'Unable to load messages.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final success = await _controller.sendMessage(
      groupId: widget.groupId,
      userName: widget.userName,
      message: messageController.text,
    );

    if (!mounted) return;
    if (success) {
      messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

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
                  adminName: admin,
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
            Expanded(child: _buildMessages()),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
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
                        fillColor: primaryColor.withOpacity(0.45),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (isLoading && chats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: chats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load messages.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No messages yet. Start the conversation.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return MessageTile(
              message: doc['message']?.toString() ?? '',
              sender: doc['sender']?.toString() ?? '',
              sentByMe: widget.userName == (doc['sender']?.toString() ?? ''),
            );
          },
        );
      },
    );
  }
}
