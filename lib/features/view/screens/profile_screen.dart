import 'package:chat_app/features/view/widgets/my_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/helper/helper_function.dart';
import '../../data/remote/service/auth_service.dart';
import '../../data/remote/service/database_service.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String email;
  const ProfileScreen({Key? key, required this.email, required this.userName})
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
          title: const Text("Profile"),
        ),
        drawer: myDrawer(context,
            userName: userName, email: email, currentRoute: "Profile"),
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
                    width: 100,
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
                      backgroundColor: Theme.of(context).primaryColor),
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
                      backgroundColor: Theme.of(context).primaryColor),
                  child: const Text("UPDATE"),
                )
              ],
            );
          }));
        });
  }
}
