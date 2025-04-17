import 'package:flutter/material.dart';
import 'package:shri_ganesh_classes/pages/admin_add_class_page.dart';
import 'package:shri_ganesh_classes/pages/admin_add_fess_page.dart';
import 'package:shri_ganesh_classes/pages/admin_add_notes_page.dart';
import 'package:shri_ganesh_classes/pages/admin_add_notice_page.dart';
import 'package:shri_ganesh_classes/pages/admin_add_student_page.dart';
import 'package:shri_ganesh_classes/pages/admin_add_test_page.dart';
import 'package:shri_ganesh_classes/pages/admin_add_vedio_page.dart';
import 'package:shri_ganesh_classes/pages/admin_list_fees_page.dart';
import 'package:shri_ganesh_classes/pages/admin_list_notice_page.dart';
import 'package:shri_ganesh_classes/pages/admin_list_vedio_page.dart';

import 'package:shri_ganesh_classes/pages/app_drawer.dart';

import 'package:shri_ganesh_classes/pages/admin_list_attendance_page.dart';
import 'package:shri_ganesh_classes/pages/admin_list_class_page.dart';
import 'package:shri_ganesh_classes/pages/admin_list_student_page.dart';
import 'package:shri_ganesh_classes/pages/admin_list_test_page.dart';
import 'package:shri_ganesh_classes/pages/admin_list_notes_page.dart';

class AdminCardDemoScreen extends StatefulWidget {
  const AdminCardDemoScreen({super.key});

  @override
  _AdminCardDemoScreenState createState() => _AdminCardDemoScreenState();
}

class _AdminCardDemoScreenState extends State<AdminCardDemoScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AdminListStudentPage(),
    AdminTestManagementPage(),
    AdminListAttendancePage(studentId: '', studentEmail: ''),
    AdminListNotesPage(),
    AdminListClassPage(),
    AdminListNoticePage(),
    AdminListFeesPage(),
    AdminVedioListPage(),
  ];

  final List<String> _titles = [
    "Student List",
    "Manage Tests",
    "Student Attendance",
    "Upload Notes",
    "Manage Classes",
    "Notices",
    "Fess",
        "Viedo"
  ];

  final List<Map<String, dynamic>> menuItems = [
    {"icon": Icons.people, "title": "Students"},
    {"icon": Icons.assignment, "title": "Tests"},
    {"icon": Icons.check_circle, "title": "Attendance"},
    {"icon": Icons.upload, "title": "Notes"},
    {"icon": Icons.class_, "title": "Class"},
    {"icon": Icons.notifications, "title": "Notices"},
    {"icon": Icons.account_balance, "title": "Fess"},
    {"icon": Icons.video_library, "title": "Viedo"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56), // Standard app bar height
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors
                .transparent, // Make background transparent to show gradient
            elevation: 0, // Remove shadow
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: _getAppBarActions(),
          ),
        ),
      ),
      drawer: LayoutBuilder(
        builder: (context, constraints) {
          double drawerWidth = constraints.maxWidth < 600
              ? MediaQuery.of(context).size.width * 0.50 // Mobile: 50%
              : MediaQuery.of(context).size.width * 0.15; // Laptop: 30%

          return SizedBox(
            width: drawerWidth,
            child: AppDrawer(onSelectPage: (index) {
              setState(() {
                _selectedIndex = index;
              });
            }),
          );
        },
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple], // **Gradient Colors**
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent, // **Transparent background**
          items: menuItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item['icon']),
              label: item['title'],
            );
          }).toList(),
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
    );
  }

  List<Widget> _getAppBarActions() {
    if (_selectedIndex == 0) {
      return [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminAddStudentPage()),
            );
          },
        ),
      ];
    } else if (_selectedIndex == 1) {
      return [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminAddTestPage()),
            );
          },
        ),
      ];
    } else if (_selectedIndex == 3) {
      return [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddNotePage()),
            );
          },
        ),
      ];
    } else if (_selectedIndex == 4) {
      return [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminAddClassPage()),
            );
          },
        ),
      ];
    } else if (_selectedIndex == 5) {
      return [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddNoticePage()),
            );
          },
        ),
      ];
    } else if (_selectedIndex == 6) {
      return [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminAddFeesPage()),
            );
          },
        ),
      ];
    } else if (_selectedIndex == 7) {
      return [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminAddVedioPage()),
            );
          },
        ),
      ];
    }
    return [];
  }
}
