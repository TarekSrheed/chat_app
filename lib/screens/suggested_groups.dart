import 'package:chat_app/screens/categories_screen.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../helper/helper_function.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import '../widgets/widgets.dart';
import 'auth/login_screen.dart';

class GroupHoppy extends StatefulWidget {
  const GroupHoppy({Key? key}) : super(key: key);

  @override
  State<GroupHoppy> createState() => _GroupHoppyState();
}

class _GroupHoppyState extends State<GroupHoppy> {
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  QuerySnapshot? searchSnapshot;
  QuerySnapshot? searchSnapshot1;
  QuerySnapshot? searchSnapshot2;
  bool hasUserSearched = false;
  String userName = "";
  String email = "";
  bool isJoined = false;
  bool isJoined1 = false;
  bool isJoined2 = false;
  User? user;
  String currentHobby = "";
  String currentHobby1 = "";
  String currentHobby2 = "";

  @override
  void initState() {
    super.initState();
    getCurrentUserIdandName();
  }

  getCurrentUserIdandName() async {
    await HelperFunctions.getUserNameFromSF().then((value) {
      setState(() {
        userName = value!;
      });
    });
    await HelperFunctions.getUserEmailFromSF().then((value) {
      setState(() {
        email = value!;
      });
    });
    await HelperFunctions.getUserHoppyFromSF().then((value) {
      setState(() {
        currentHobby = value!;
      });
    });
    await HelperFunctions.getUserHoppy1FromSF().then((value) {
      setState(() {
        currentHobby1 = value!;
      });
    });
    await HelperFunctions.getUserHoppy2FromSF().then((value) {
      setState(() {
        currentHobby2 = value!;
      });
    });

    user = FirebaseAuth.instance.currentUser;
  }

  String getName(String r) {
    return r.substring(r.indexOf("_") + 1);
  }

  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  AuthService authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          title: Text(
            "",
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        drawer: Drawer(
            child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 50),
          children: <Widget>[
            Icon(
              Icons.account_circle,
              size: 150,
              color: Colors.grey[700],
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              userName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 30,
            ),
            const Divider(
              height: 2,
            ),
            ListTile(
              onTap: () {
                nextScreen(context, HomeScreen());
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.groups),
              title: const Text(
                "Groups",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ListTile(
              onTap: () {
                nextScreenReplace(
                    context, ProfileScreen(email: email, userName: userName));
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.person),
              title: const Text(
                "Profile",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ListTile(
              onTap: () {},
              selected: true,
              selectedColor: Theme.of(context).primaryColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.group),
              title: const Text(
                "Suggested groups",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ListTile(
              onTap: () {
                nextScreenReplace(
                  context,
                  CategoriesScreen(
                    userName: userName,
                    email: email,
                  ),
                );
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.category_rounded),
              title: const Text(
                "Categories",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ListTile(
              onTap: () async {
                showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.black, fontSize: 25),
                        ),
                        content: const Text("Are you sure you want to logout?"),
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
                              await authService.signOut();
                              Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginScreen()),
                                  (route) => false);
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.exit_to_app),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.black),
              ),
            )
          ],
        )),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  children: [
                    const SizedBox(width: 65),
                    TextButton(
                      onPressed: () {
                        initiateSearchMethod();
                        initiateSearchMethod1();
                        initiateSearchMethod2();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).primaryColor,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: const Text("View suggested groups",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor),
                    )
                  : groupList(),
              groupList1(),
              groupList2(),
            ],
          ),
        ),
      ),
    );
  }

  initiateSearchMethod() async {
    if (currentHobby.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      await DatabaseService()
          .searchByhoppy(
        currentHobby,
      )
          .then((snapshot) {
        setState(() {
          searchSnapshot = snapshot;
          isLoading = false;
          hasUserSearched = true;
        });
      });
    }
  }

  initiateSearchMethod1() async {
    if (currentHobby1.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      await DatabaseService()
          .searchByhoppy1(
        currentHobby1,
      )
          .then((snapshot) {
        setState(() {
          searchSnapshot1 = snapshot;
          isLoading = false;
          hasUserSearched = true;
        });
      });
    }
  }

  initiateSearchMethod2() async {
    if (currentHobby2.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      await DatabaseService()
          .searchByhoppy2(
        currentHobby2,
      )
          .then((snapshot) {
        setState(() {
          searchSnapshot2 = snapshot;
          isLoading = false;
          hasUserSearched = true;
        });
      });
    }
  }
  // initiateSearchMethod() async {
  //   if (searchController.text.isNotEmpty) {
  //     setState(() {
  //       isLoading = true;
  //     });
  //     await DatabaseService()
  //         .searchByName(searchController.text)
  //         .then((snapshot) {
  //       setState(() {
  //         searchSnapshot = snapshot;
  //         isLoading = false;
  //         hasUserSearched = true;
  //       });
  //     });
  //   }
  // }

  groupList() {
    return hasUserSearched
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: searchSnapshot!.docs.length,
            itemBuilder: (context, index) {
              return groupTile(
                userName,
                searchSnapshot!.docs[index]['groupId'],
                searchSnapshot!.docs[index]['groupName'],
                searchSnapshot!.docs[index]['admin'],
              );
            },
          )
        : Container();
  }

  groupList1() {
    return hasUserSearched
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: searchSnapshot1!.docs.length,
            itemBuilder: (context, index) {
              return groupTile1(
                userName,
                searchSnapshot1!.docs[index]['groupId'],
                searchSnapshot1!.docs[index]['groupName'],
                searchSnapshot1!.docs[index]['admin'],
              );
            },
          )
        : Container();
  }

  groupList2() {
    return hasUserSearched
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: searchSnapshot2!.docs.length,
            itemBuilder: (context, index) {
              return groupTile2(
                userName,
                searchSnapshot2!.docs[index]['groupId'],
                searchSnapshot2!.docs[index]['groupName'],
                searchSnapshot2!.docs[index]['admin'],
              );
            },
          )
        : Container();
  }

  joinedOrNot(
      String userName, String groupId, String groupname, String admin) async {
    await DatabaseService(uid: user!.uid)
        .isUserJoined(groupname, groupId, userName)
        .then((value) {
      setState(() {
        isJoined = value;
      });
    });
  }

  joinedOrNot1(
      String userName, String groupId, String groupname, String admin) async {
    await DatabaseService(uid: user!.uid)
        .isUserJoined(groupname, groupId, userName)
        .then((value) {
      setState(() {
        isJoined1 = value;
      });
    });
  }

  joinedOrNot2(
      String userName, String groupId, String groupname, String admin) async {
    await DatabaseService(uid: user!.uid)
        .isUserJoined(groupname, groupId, userName)
        .then((value) {
      setState(() {
        isJoined2 = value;
      });
    });
  }

  Widget groupTile(
      String userName, String groupId, String groupName, String admin) {
    // function to check whether user already exists in group
    joinedOrNot(userName, groupId, groupName, admin);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          groupName.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title:
          Text(groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text("Admin: ${getName(admin)}"),
      trailing: InkWell(
        onTap: () async {
          await DatabaseService(uid: user!.uid)
              .toggleGroupJoin1(groupId, userName, groupName);
          if (isJoined) {
            setState(() {
              isJoined = !isJoined;
            });
            showSnackbar(context, Colors.green, "Successfully joined he group");
            Future.delayed(const Duration(seconds: 2), () {
              // nextScreen(
              //     context,
              //     ChatScreen(
              //         groupId: groupId,
              //         groupName: groupName,
              //         userName: userName));
            });
          } else {
            setState(() {
              isJoined = !isJoined;
              showSnackbar(context, Colors.red, "Left the group $groupName");
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).primaryColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: const Text("Join Now", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget groupTile1(
      String userName, String groupId, String groupName, String admin) {
    // function to check whether user already exists in group
    joinedOrNot1(userName, groupId, groupName, admin);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          groupName.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title:
          Text(groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text("Admin: ${getName(admin)}"),
      trailing: InkWell(
        onTap: () async {
          await DatabaseService(uid: user!.uid)
              .toggleGroupJoin1(groupId, userName, groupName);
          if (isJoined1) {
            setState(() {
              isJoined1 = !isJoined1;
            });
            showSnackbar(context, Colors.green, "Successfully joined he group");
            Future.delayed(const Duration(seconds: 2), () {
              // nextScreen(
              //     context,
              //     ChatScreen(
              //         groupId: groupId,
              //         groupName: groupName,
              //         userName: userName));
            });
          } else {
            setState(() {
              isJoined1 = !isJoined1;
              showSnackbar(context, Colors.red, "Left the group $groupName");
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).primaryColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: const Text("Join Now", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget groupTile2(
      String userName, String groupId, String groupName, String admin) {
    // function to check whether user already exists in group
    joinedOrNot2(userName, groupId, groupName, admin);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          groupName.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title:
          Text(groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text("Admin: ${getName(admin)}"),
      trailing: InkWell(
        onTap: () async {
          await DatabaseService(uid: user!.uid)
              .toggleGroupJoin1(groupId, userName, groupName);
          if (isJoined2) {
            setState(() {
              isJoined2 = !isJoined2;
            });
            showSnackbar(context, Colors.green, "Successfully joined he group");
            Future.delayed(const Duration(seconds: 2), () {
              // nextScreen(
              //     context,
              //     ChatScreen(
              //         groupId: groupId,
              //         groupName: groupName,
              //         userName: userName));
            });
          } else {
            setState(() {
              isJoined2 = !isJoined2;
              showSnackbar(context, Colors.red, "Left the group $groupName");
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).primaryColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: const Text("Join Now", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
