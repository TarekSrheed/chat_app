import 'package:chat_app/screens/auth/login_screen.dart';
import 'package:chat_app/screens/categories_screen.dart';
import 'package:chat_app/screens/suggested_groups.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../helper/helper_function.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  String userName;
  String email;
  ProfileScreen({Key? key, required this.email, required this.userName})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthService authService = AuthService();
  String userName = "";
  String email = "";
  String age = "";
  String newName = "";
  bool _isLoading = false;

  User? user;
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
    await HelperFunctions.getUserAgeFromSF().then((value) {
      setState(() {
        age = value!;
      });
    });
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          title: const Text(
            "Profile",
            style: TextStyle(
                color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold),
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
              widget.userName,
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
              onTap: () {},
              selected: true,
              selectedColor: Theme.of(context).primaryColor,
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
                    userName: widget.userName,
                    email: widget.email,
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
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 70),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.account_circle,
                size: 200,
                color: Colors.grey[700],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Full Name",
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(
                    width: 120,
                  ),
                  Text(widget.userName, style: const TextStyle(fontSize: 15)),
                  IconButton(
                      onPressed: () {
                        popUpDialog(context);
                      },
                      icon: Icon(
                        Icons.edit,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      )),
                ],
              ),
              Row(
                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text("Age",
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(
                    width: 185,
                  ),
                  Text(age, style: const TextStyle(fontSize: 15)),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Email",
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontStyle: FontStyle.italic)),
                  Text(widget.email, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  popUpDialog(BuildContext context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setState) {
            return AlertDialog(
              title: Text(
                'Edit your name',
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
                              newName = val;
                            });
                          },
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                              hintText: 'Enter your new name',
                              hintStyle: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 15),
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
                  // const SizedBox(height: 10),
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
                    if (newName != "") {
                      // setState(() {
                      //   _isLoading = true;
                      // });
                      DatabaseService(
                              uid: FirebaseAuth.instance.currentUser!.uid)
                          .updateUserData(
                        newName,
                      );
                      //     .whenComplete(() {
                      //   _isLoading = false;
                      // });
                      Navigator.of(context).pop();
                      showSnackbarProfile(context, Colors.green,
                          "You need to re-login to update your name");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).primaryColor),
                  child: const Text("UPDATE"),
                )
              ],
            );
          }));
        });
  }
}
