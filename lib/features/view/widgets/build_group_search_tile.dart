import 'package:chat_app/features/view/screens/chat_screen.dart';
import 'package:chat_app/features/view/widgets/widgets.dart';
import 'package:flutter/material.dart';

Widget buildGroupSearchTile(
    {required String groupId,
    required String groupName,
    required String userName,
    // required String admin,
    required BuildContext context,
    required String subtitle,
    required bool isJoined,
    required bool istrailing,
    required void Function()? onPressed}) {
  return ListTile(
    onTap: isJoined? () {
        nextScreen(
            context,
            ChatScreen(
                groupId: groupId,
                groupName: groupName,
                userName: userName,
                ));
    }:(){},
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
    leading: CircleAvatar(
      radius: 25,
      backgroundColor: Theme.of(context).primaryColor,
      child: Text(
        groupName.isNotEmpty ? groupName.substring(0, 1).toUpperCase() : "?",
        style: const TextStyle(color: Colors.white),
      ),
    ),
    title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text( subtitle),
    trailing: istrailing ?  ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isJoined ? Colors.black54 : Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Text(
        isJoined ? "Joined" : "Join Now",
        style: const TextStyle(color: Colors.white),
      ),
    ): null,
  );
}
