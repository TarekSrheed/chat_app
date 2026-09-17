import 'package:chat_app/features/view/screens/chat_screen.dart';
import 'package:chat_app/features/view/widgets/widgets.dart';
import 'package:flutter/material.dart';

class GroupTile extends StatelessWidget {
  final String userName;
  final String groupId;
  final String groupName;
  final String recentMessage;
  final String recentSender;
  const GroupTile(
      {Key? key,
      required this.groupId,
      required this.groupName,
      required this.userName, required this.recentMessage, required this.recentSender})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        nextScreen(
            context,
            ChatScreen(
                groupId: groupId,
                groupName: groupName,
                userName: userName,
                ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              groupName.substring(0, 1).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          title: Text(
            groupName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        
            subtitle: recentMessage.isNotEmpty  ? Text(
            "$recentSender: $recentMessage",
            style: const TextStyle(fontSize: 13),
          ): null,
          
        ),
      ),
    );
  }
}
