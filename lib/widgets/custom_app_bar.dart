// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shri_ganesh_classes/pages/login_page.dart';
import 'package:shri_ganesh_classes/pages/user_profile_page.dart'; // Profile page import

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String email;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final VoidCallback onLogout;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.email,
    this.scaffoldKey,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<int>(
          icon: Icon(Icons.account_circle, size: 30, color: Colors.white),
          onSelected: (value) async {
            if (value == 1) {
              // Navigate to View Profile Page
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage()), // Navigate to Profile Page
              );
            } else if (value == 2) {
              // Logout Functionality
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn'); // Remove login session

              // ✅ Navigate to LoginPage & clear all previous routes
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("View Profile"),
                ],
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Logout"),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
