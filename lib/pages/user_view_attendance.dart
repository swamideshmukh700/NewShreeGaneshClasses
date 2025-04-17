// ignore_for_file: library_private_types_in_public_api, avoid_print, unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:shri_ganesh_classes/widgets/bottom_navigation.dart';
import 'package:shri_ganesh_classes/widgets/custom_app_bar.dart';

class UserViewAttendance extends StatefulWidget {
  final String studentEmail;
  final String studentId;
  final dynamic studentClass;

  const UserViewAttendance({
    super.key,
    required this.studentEmail,
    required this.studentId, //  Make sure it's included
    required this.studentClass,
  });

  @override
  _UserViewAttendanceState createState() => _UserViewAttendanceState();
}

class _UserViewAttendanceState extends State<UserViewAttendance> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Define scaffold key

  bool _isHoveredCalendar = false;
  // ignore: unused_field
  bool _isDateFocused = false;
  String? studentId;
  bool isLoading = true;
  List<Map<String, dynamic>> attendanceRecords = [];
  String? selectedDate;
  String? studentClass; // Store student class in state
  @override
  void initState() {
    super.initState();
    _fetchStudentIdAndAttendance();
  }

  Future<void> _fetchStudentIdAndAttendance() async {
    try {
      // Fetch student ID using email
      QuerySnapshot studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: widget.studentEmail)
          .limit(1)
          .get();

      if (studentQuery.docs.isEmpty) {
        studentQuery = await FirebaseFirestore.instance
            .collection('students')
            .where('userName', isEqualTo: widget.studentEmail)
            .limit(1)
            .get();
      }

      if (studentQuery.docs.isNotEmpty) {
        var studentData =
            studentQuery.docs.first.data() as Map<String, dynamic>;
        String userName = studentData['userName'] ?? 'Unknown'; //
        String studentClass = studentData['class']?.toString().trim() ?? '';

        setState(() {
          this.studentClass = studentClass;
        });
      }
      // Extract student document data
      DocumentSnapshot studentDoc = studentQuery.docs.first;
      Map<String, dynamic> studentData =
          studentDoc.data() as Map<String, dynamic>;

      // Fetch class and student ID
      String fetchedStudentClass = studentData['class'] ?? 'Not Assigned';
      String fetchedStudentId = studentDoc.id;

      setState(() {
        studentClass = fetchedStudentClass; //  Store in state
        studentId = fetchedStudentId; //  Store in state
      });
      // Fetch attendance where studentId exists
      QuerySnapshot attendanceQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where(studentId!, isGreaterThanOrEqualTo: '')
          .get();

      List<Map<String, dynamic>> fetchedAttendance = [];

      for (var doc in attendanceQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String date = doc.id;
        String status =
            data.containsKey(studentId) ? data[studentId] : "Not Marked";

        fetchedAttendance.add({"date": date, "status": status});
      }
// **Date-wise Descending Sorting**
      fetchedAttendance.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        attendanceRecords = fetchedAttendance;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching attendance: $e");
      setState(() => isLoading = false);
    }
  }

  void _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    setState(() {
      selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate!);
      _isDateFocused = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() => _isDateFocused = false);
    });
  }

  // ignore: unused_element
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 125, 58, 212)),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredRecords = selectedDate == null
        ? attendanceRecords
        : attendanceRecords
            .where((record) => record['date'] == selectedDate)
            .toList();

    return Scaffold(
      key: _scaffoldKey, // Assign key to Scaffold
      appBar: CustomAppBar(
        title: "View Attendance",
        scaffoldKey: _scaffoldKey,
        email: widget.studentEmail,
        onLogout: () {},
      ),
    
      bottomNavigationBar: BottomNavigation(
        email: widget.studentEmail,
        studentId: widget.studentId,
        selectedIndex: 3, // Change based on the current page
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHoveredCalendar = true),
                      onExit: (_) => setState(() => _isHoveredCalendar = false),
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(255, 127, 58, 192),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: _isHoveredCalendar
                                ? const Color.fromARGB(255, 53, 2, 110)
                                : Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filteredRecords.isEmpty
                      ? const Center(
                          child: Text("No attendance records found."),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            return Card(
                              color: Colors.white,
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                title: Text(
                                  "Date: ${record['date']}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: record['status'] == "Present"
                                        ? Colors.green.shade600
                                        : (record['status'] == "Absent"
                                            ? Colors.red.shade600
                                            : Colors.black),
                                  ),
                                ),
                                subtitle: Text(
                                  "Status: ${record['status']}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: record['status'] == "Present"
                                        ? Colors.green.shade600
                                        : (record['status'] == "Absent"
                                            ? Colors.red.shade600
                                            : Colors.black),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
