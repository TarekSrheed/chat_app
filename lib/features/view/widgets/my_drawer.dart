import 'package:chat_app/features/data/remote/service/auth_service.dart';
import 'package:chat_app/features/view/screens/auth/login_screen.dart';
import 'package:chat_app/features/view/screens/categories_screen.dart';
import 'package:chat_app/features/view/screens/home_screen.dart';
import 'package:chat_app/features/view/screens/profile_screen.dart';
import 'package:chat_app/features/view/screens/suggested_groups.dart';
import 'package:chat_app/features/view/widgets/widgets.dart';
import 'package:flutter/material.dart';

Widget myDrawer(
  BuildContext context, {
  required String userName,
  required String email,
  required String currentRoute,
}) {
  void showLogoutDialog() {
    final AuthService authService = AuthService();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout",
            style: TextStyle(color: Colors.black, fontSize: 22)),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel, color: Colors.red),
          ),
          IconButton(
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.done, color: Colors.green),
          ),
        ],
      ),
    );
  }

  return Drawer(
    child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor:
              Theme.of(context).primaryColor.withValues(alpha: 0.3),
          child: Icon(Icons.account_circle,
              size: 70, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 12),
        Text(
          userName.isEmpty ? 'Welcome' : userName,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Divider(),
        _buildDrawerItem(Icons.groups, 'Groups', currentRoute == 'Groups', () {
          currentRoute == 'Groups'
              ? Navigator.pop(context)
              : nextScreenReplace(context, const HomeScreen());
        }, context),
        _buildDrawerItem(Icons.person, 'Profile', currentRoute == 'Profile',
            () {
          nextScreenReplace(
            context,
            ProfileScreen(userName: userName, email: email),
          );
        }, context),
        _buildDrawerItem(
            Icons.group, 'Suggested groups', currentRoute == 'Suggested groups',
            () {
          nextScreenReplace(context, const SuggestedGroups());
        }, context),
        _buildDrawerItem(
            Icons.category_rounded, 'Categories', currentRoute == 'Categories',
            () {
          nextScreenReplace(
            context,
            CategoriesScreen(userName: userName, email: email),
          );
        }, context),
        _buildDrawerItem(
            Icons.exit_to_app, 'Logout', false, showLogoutDialog, context),
      ],
    ),
  );
}

Widget _buildDrawerItem(IconData icon, String label, bool selected,
    VoidCallback onTap, BuildContext context) {
  return ListTile(
    leading:
        Icon(icon, color: selected ? Theme.of(context).primaryColor : null),
    title: Text(label),
    selected: selected,
    selectedColor: Colors.black,
    onTap: onTap,
  );
}
