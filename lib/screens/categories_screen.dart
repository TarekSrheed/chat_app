import 'package:chat_app/screens/auth/login_screen.dart';
import 'package:chat_app/screens/suggested_groups.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';

import '../app_data.dart';
import '../service/auth_service.dart';
import '../widgets/category_item.dart';
import '../widgets/widgets.dart';

class CategoriesScreen extends StatefulWidget {
  String userName;
  String email;
  CategoriesScreen({Key? key, required this.email, required this.userName})
      : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  AuthService authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          title: Column(
            children: const [
              Text(
                "Find the best groups",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                " that work for you",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ],
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
              onTap: () {
                nextScreenReplace(
                  context,
                  ProfileScreen(
                    userName: widget.userName,
                    email: widget.email,
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
              onTap: () {},
              selected: true,
              selectedColor: Theme.of(context).primaryColor,
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
                            style:
                                TextStyle(color: Colors.black, fontSize: 25)),
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
        body: GridView(
          padding: const EdgeInsets.all(10.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170,
            childAspectRatio: 7 / 8,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          children: categories_data
              .map(
                (categoryData) => CategoryItem(
                  id: categoryData.id,
                  title: categoryData.title,
                  imageUrl: categoryData.imageUrl,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
