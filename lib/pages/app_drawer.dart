// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shri_ganesh_classes/pages/login_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AppDrawer extends StatefulWidget {
  final Function(int) onSelectPage;
  const AppDrawer({super.key, required this.onSelectPage});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _menuItems = [
      {'icon': Icons.people, 'title': 'Students', 'index': 0},
      {'icon': Icons.assignment, 'title': 'Tests', 'index': 1},
      {'icon': Icons.check_circle, 'title': 'Attendance', 'index': 2},
      {'icon': Icons.upload, 'title': 'Notes', 'index': 3},
      {'icon': Icons.class_, 'title': 'Class', 'index': 4},
      {'icon': Icons.notifications, 'title': 'Notices', 'index': 5},
      {'icon': Icons.account_balance, 'title': 'Fess', 'index': 6},
      {'icon': Icons.videocam, 'title': 'Viedo', 'index': 7},
    ];
    _filteredItems = List.from(_menuItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMenu(String query) {
    setState(() {
      _filteredItems = _menuItems
          .where((item) =>
              item['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterMenu,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          // 🔹 List with Gradient Icon
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ).createShader(bounds),
                    child: Icon(
                      _filteredItems[index]['icon'],
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    _filteredItems[index]['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelectPage(_filteredItems[index]['index']);
                  },
                );
              },
            ),
          ),

          // 🔹 Logout Button with Gradient Icon
          ListTile(
            leading: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ).createShader(bounds),
              child: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
            ),
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ).createShader(bounds),
              child:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
            onTap: () async {
              // ✅ Logout logic
              SharedPreferences prefs = await SharedPreferences.getInstance();

              await prefs.clear(); // OR use remove('userType') etc.

              // Optional: clear FCM Token
              await FirebaseMessaging.instance.deleteToken();
              await prefs.remove('isLoggedIn'); // Remove login session

              // ✅ Navigate to LoginPage & clear all previous routes
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
