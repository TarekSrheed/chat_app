import 'package:chat_app/screens/auth/login_screen.dart';
import 'package:chat_app/screens/categories_screen.dart';
import 'package:chat_app/screens/suggested_groups.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/screens/search_screen.dart';
import 'package:chat_app/shared/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../helper/helper_function.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import '../widgets/group_tile.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// String currentHobby = '';
// String currentHobby1 = '';
// String currentHobby2 = '';

class _HomeScreenState extends State<HomeScreen> {
  String userName = "";
  String email = "";
  AuthService authService = AuthService();
  Stream? groups;
  bool _isLoading = false;
  String groupName = "";
  String groupType = "";

  @override
  void initState() {
    super.initState();
    gettingUserData();
  }

// string manipulation
  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  String getName(String res) {
    return res.substring(res.indexOf("_") + 1);
  }

  gettingUserData() async {
    await HelperFunctions.getUserEmailFromSF().then((value) {
      setState(() {
        email = value!;
      });
    });
    await HelperFunctions.getUserNameFromSF().then((val) {
      setState(() {
        userName = val!;
      });
    });
    // getting the list of snapshots in our stream
    await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getUserGroups()
        .then((snapshot) {
      setState(() {
        groups = snapshot;
      });
    });
  }

  String currentHobby = "Fashion";
  final List<String> hobbys = [
    'Art',
    'Animal care',
    'Cars',
    'Education',
    'Fashion',
    'Games',
    'History',
    'Music',
    'Social',
    'Sport'
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              nextScreen(context, SearchScreen());
            },
            icon: const Icon(Icons.search),
          ),
        ],
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Groups",
          style: TextStyle(
              fontSize: 27, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
          child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 30),
        children: <Widget>[
          Icon(
            Icons.account_circle,
            size: 135,
            color: Colors.grey[700],
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            userName,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.normal,
                fontSize: 15),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          const Divider(
            height: 3,
          ),
          ListTile(
            onTap: () {},
            selectedColor: Theme.of(context).primaryColor,
            selected: true,
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
                context,
                ProfileScreen(
                  userName: userName,
                  email: email,
                ),
              );
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
            onTap: () {
              nextScreenReplace(
                context,
                GroupHoppy(),
              );
            },
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
                      title: const Text("Logout",
                          style: TextStyle(color: Colors.black, fontSize: 25)),
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
                                    builder: (context) => const LoginScreen()),
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
      body: groupList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          popUpDialog(context);
        },
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    ));
  }

  popUpDialog(BuildContext context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setState) {
            return AlertDialog(
              title: Text(
                'Create a group',
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoading == true
                      ? Center(
                          child: CircularProgressIndicator(
                              color: Theme.of(context).primaryColor),
                        )
                      : TextField(
                          onChanged: (val) {
                            setState(() {
                              groupName = val;
                            });
                          },
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                              hintText: 'Group Name',
                              hintStyle: TextStyle(
                                  color: Theme.of(context).primaryColor),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(20)),
                              errorBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.circular(20)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(20))),
                        ),
                  const SizedBox(height: 10),
                  Text(
                    'Choose the group type',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownButtonFormField<String>(
                    value: currentHobby,
                    decoration: textInputDecoration,
                    items: hobbys
                        .map((hobby) => DropdownMenuItem<String>(
                              value: hobby,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: kDefaultPadding * 3.7),
                                child: Text(
                                  hobby,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => currentHobby = val!),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).primaryColor),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (groupName != "") {
                      setState(() {
                        _isLoading = true;
                      });
                      DatabaseService(
                              uid: FirebaseAuth.instance.currentUser!.uid)
                          .createGroup(
                              userName,
                              FirebaseAuth.instance.currentUser!.uid,
                              groupName,
                              currentHobby)
                          .whenComplete(() {
                        _isLoading = false;
                      });
                      Navigator.of(context).pop();
                      showSnackbar(
                          context, Colors.green, "Group created successfully.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).primaryColor),
                  child: const Text("CREATE"),
                )
              ],
            );
          }));
        });
  }

  groupList() {
    return StreamBuilder(
      stream: groups,
      builder: (context, AsyncSnapshot snapshot) {
        // make some checks
        if (snapshot.hasData) {
          if (snapshot.data['groups'] != null) {
            if (snapshot.data['groups'].length != 0) {
              return ListView.builder(
                itemCount: snapshot.data['groups'].length,
                itemBuilder: (context, index) {
                  int reverseIndex = snapshot.data['groups'].length - index - 1;
                  return GroupTile(
                      groupId: getId(snapshot.data['groups'][reverseIndex]),
                      groupName: getName(snapshot.data['groups'][reverseIndex]),
                      userName: snapshot.data['fullName']);
                },
              );
            } else {
              return noGroupWidget();
            }
          } else {
            return noGroupWidget();
          }
        } else {
          return Center(
            child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor),
          );
        }
      },
    );
  }

  noGroupWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              popUpDialog(context);
            },
            child: Icon(
              Icons.add_circle,
              color: Colors.grey[700],
              size: 75,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            "You've not joined any groups, tap on the add icon to create a group or also search from top search button.",
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
