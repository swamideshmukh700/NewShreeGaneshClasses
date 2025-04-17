import 'package:flutter/material.dart';
import 'package:shri_ganesh_classes/pages/login_page.dart';
import 'package:shri_ganesh_classes/pages/user_test_list_page.dart';
import 'package:shri_ganesh_classes/pages/user_view_attendance.dart';
import 'package:shri_ganesh_classes/pages/user_view_fees.dart';
import 'package:shri_ganesh_classes/pages/user_view_notes.dart';
import 'package:shri_ganesh_classes/pages/user_view_viedo.dart';

class UserDashboardPage extends StatefulWidget {
  final String email;
  final String studentClass;

  const UserDashboardPage({
    super.key,
    required this.email,
    required this.studentClass,
    required,
  });

  @override
  _UserDashboardPageState createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Create scaffold key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign key to Scaffold

      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.account_circle,
                          size: 50, color: Colors.blue)),
                  const SizedBox(height: 10),
                  Text(widget.email,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text("Class: ${widget.studentClass}",
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildDrawerItem(Icons.book, "View Fees", () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserViewFees(
                            studentEmail: widget.email,
                            studentId: '',
                            studentClass: '',
                            firstName: '',
                            email: '',
                          )));
            }),
            const SizedBox(height: 10),
            _buildDrawerItem(Icons.assignment, "View Test", () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserTestListPage(
                            studentEmail: widget.email,
                            tests: '',
                            studentId: '',
                            studentClass: '',
                            testId: '',
                            fullName: '',
                          )));
            }),
            _buildDrawerItem(Icons.book, "View Notes", () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserViewNotes(
                            studentEmail: widget.email,
                            studentId: '',
                            studentClass: '',
                            firstName: '',
                            email: '',
                          )));
            }),
            _buildDrawerItem(Icons.book, "View Veido", () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserViewViedo(
                            studentEmail: widget.email,
                            studentId: '',
                            studentClass: '',
                         
                          )));
            }),
            _buildDrawerItem(Icons.event_available, "View Attendance", () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserViewAttendance(
                            studentEmail: widget.email,
                            studentId: '',
                            studentClass: '',
                          )));
            }),
            const Spacer(),
            Container(
              width: double.infinity,
              color: Colors.black,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
              child: UserViewViedo(
            studentEmail: widget.email,
            studentId: '',
            studentClass: '',
           
          )),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
