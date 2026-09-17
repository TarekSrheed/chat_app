import 'package:chat_app/features/data/remote/service/presence_service.dart';
import 'package:chat_app/features/view/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../data/remote/service/database_service.dart';
import '../widgets/widgets.dart';

class GroupInfo extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String adminName;
  const GroupInfo(
      {super.key,
      required this.adminName,
      required this.groupName,
      required this.groupId});

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  Stream? members;

  @override
  void initState() {
    getMembers();
    super.initState();
  }

  Future<void> getMembers() async {
    final val = DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getGroupMembers(widget.groupId);
    if (!mounted) return;
    setState(() {
      members = val;
    });
  }

  String getName(String r) {
    if (r.contains("_")) {
      return r.substring(r.indexOf("_") + 1);
    }
    return r;
  }

  String getId(String res) {
    if (res.contains("_")) {
      return res.substring(0, res.indexOf("_"));
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text("Group Info"),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          "Exit Group",
                          style: TextStyle(color: Colors.black),
                        ),
                        content: const Text(
                            "Are you sure you want to exit the group?"),
                        actions: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              DatabaseService(
                                      uid: FirebaseAuth
                                          .instance.currentUser!.uid)
                                  .toggleGroupJoin(
                                      widget.groupId,
                                      getName(widget.adminName),
                                      widget.groupName)
                                  .whenComplete(() {
                                nextScreenReplace(context, const HomeScreen());
                              });
                            },
                            icon: const Icon(
                              Icons.done,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      );
                    });
              },
              icon: const Icon(Icons.exit_to_app))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).primaryColor.withOpacity(0.1)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      widget.groupName.isNotEmpty
                          ? widget.groupName.substring(0, 1).toUpperCase()
                          : "G",
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Group: ${widget.groupName}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Admin: ${getName(widget.adminName)}",
                          style: const TextStyle(color: Colors.grey),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            memberList(),
          ],
        ),
      ),
    );
  }

  Widget memberList() {
    return StreamBuilder(
      stream: members,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final membersList = snapshot.data['members'] as List?;

          if (membersList != null && membersList.isNotEmpty) {
            return ListView.builder(
              itemCount: membersList.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final rawMember = membersList[index].toString();
                // استخراج الـ UID سواء كان نصاً صريحاً أو نصاً مركباً old_format (uid_name)
                final userId = getId(rawMember);

                return buildMemberTile(userId);
              },
            );
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("NO MEMBERS"),
              ),
            );
          }
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading members"));
        } else {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }
      },
    );
  }

  Widget buildMemberTile(String userId) {
    // 1. جلب بيانات المستخدم (مثل الاسم) من Firestore باستخدام Uid
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        String displayName = "Loading...";
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          displayName = userData?['fullName'] ?? userData?['name'] ?? "User";
        }

        // 2. الاستماع لحالة الاتصال الحية عبر Realtime Database
        return StreamBuilder<DatabaseEvent>(
          stream: PresenceService().getUserPresenceStream(userId),
          builder: (context, presenceSnapshot) {
            bool isOnline = false;
            if (presenceSnapshot.hasData &&
                presenceSnapshot.data!.snapshot.value != null) {
              final data = Map<String, dynamic>.from(
                  presenceSnapshot.data!.snapshot.value as Map);
              isOnline = data['isOnline'] ?? false;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName.substring(0, 1).toUpperCase()
                            : "U",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isOnline ? "Online" : "Offline",
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: isOnline ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
