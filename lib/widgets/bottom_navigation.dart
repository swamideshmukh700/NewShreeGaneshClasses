import 'package:flutter/material.dart';
import 'package:shri_ganesh_classes/pages/user_test_list_page.dart';
import 'package:shri_ganesh_classes/pages/user_view_attendance.dart';
import 'package:shri_ganesh_classes/pages/user_view_fees.dart';
import 'package:shri_ganesh_classes/pages/user_view_notes.dart';
import 'package:shri_ganesh_classes/pages/user_view_notices.dart';
import 'package:shri_ganesh_classes/pages/user_view_viedo.dart';

class BottomNavigation extends StatelessWidget {
  final String email;
  final String studentId;
  final int selectedIndex;

  const BottomNavigation({
    super.key,
    required this.email,
    required this.studentId,
    required this.selectedIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return; // Prevent unnecessary navigation

    Widget nextPage;

    switch (index) {
      case 0:
        // ignore: prefer_typing_uninitialized_variables
        var studentClass;
        nextPage = UserViewViedo(
          studentEmail: email,
          studentId: studentId,
          studentClass: studentClass ?? '',
        );
        break;
      case 1:
        // ignore: prefer_typing_uninitialized_variables
        var studentClass;
        nextPage = UserTestListPage(
          studentEmail: email,
          studentId: studentId,
          studentClass: studentClass ?? '',
          tests: '',
          testId: '',
          fullName: '',
        );
        break;

      case 2:
        // ignore: prefer_typing_uninitialized_variables
        var studentClass;
        nextPage = UserViewNotes(
          studentEmail: email,
          studentId: studentId,
          studentClass: studentClass ?? '',
          firstName: '',
          email: '',
        );
        break;
      case 3:
        // ignore: prefer_typing_uninitialized_variables
        var studentClass;
        nextPage = UserViewAttendance(
          studentEmail: email,
          studentId: studentId,
          studentClass: studentClass ?? '',
        );
        break;
      case 4:
        // ignore: prefer_typing_uninitialized_variables
        var studentClass;
        nextPage = UserViewNotices(
          studentEmail: email,
          studentId: studentId,
          studentClass: studentClass ?? '',
        );
        break;
      case 5:
        // ignore: prefer_typing_uninitialized_variables
        var studentClass;
        nextPage = UserViewFees(
          studentEmail: email,
          studentId: studentId,
          studentClass: studentClass ?? '',
          firstName: '',
          email: '',
        );
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple], // 🎨 Blue to Purple Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomIcon(context, Icons.videocam, "Veidos",
              const Color.fromARGB(255, 240, 110, 100), 0),
          _buildBottomIcon(context, Icons.assignment, "Tests",
              const Color.fromARGB(255, 11, 186, 17), 1),
          _buildBottomIcon(context, Icons.book, "Notes", Colors.orange, 2),
          _buildBottomIcon(context, Icons.event_available, "Attendance",
              const Color.fromARGB(255, 193, 6, 225), 3),
          _buildBottomIcon(context, Icons.notifications, "Notice",
              const Color.fromARGB(255, 240, 44, 31), 4),
          _buildBottomIcon(context, Icons.attach_money, "Fees",
              const Color.fromARGB(255, 240, 138, 194), 5),
        ],
      ),
    );
  }

  Widget _buildBottomIcon(BuildContext context, IconData icon, String label,
      Color color, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selectedIndex == index ? color : Colors.white,
            size: 30,
          ),
          Text(
            label,
            style: TextStyle(
              color: selectedIndex == index ? Colors.white : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
