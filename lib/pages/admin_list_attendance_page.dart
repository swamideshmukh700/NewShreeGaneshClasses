// ignore_for_file: avoid_print, library_private_types_in_public_api, unused_field, prefer_final_fields, unnecessary_cast, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shri_ganesh_classes/pages/app_drawer.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminListAttendancePage extends StatefulWidget {
  const AdminListAttendancePage(
      {super.key, required String studentEmail, required String studentId});

  @override
  _AdminListAttendancePageState createState() =>
      _AdminListAttendancePageState();
}

class _AdminListAttendancePageState extends State<AdminListAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _attendance = {};
  String? selectedClass;
  List<String> classList = ["Selecte Class"];
  final String _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final TimeOfDay _startAttendanceTime = const TimeOfDay(hour: 9, minute: 0);
  final TimeOfDay _endAttendanceTime = const TimeOfDay(hour: 17, minute: 0);

  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  CalendarFormat _calendarFormat = CalendarFormat.month;

  bool _showCalendar = false;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> isHoveringTitle = ValueNotifier(false);
  final ValueNotifier<bool> isHoveringBackArrow = ValueNotifier(false);
  final ValueNotifier<bool> isHoveringTodayButton = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _fetchStudentsAndAttendance(_selectedDate);
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    var classSnapshot = await _firestore.collection('class').get();
    setState(() {
      classList.addAll(
          classSnapshot.docs.map((doc) => doc['name'] as String).toList());
      selectedClass = "Selecte Class";
    });
  }

  Future<void> _fetchStudentsAndAttendance(String date) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final studentsSnapshot = await _firestore.collection('students').get();
      _students = studentsSnapshot.docs.map((doc) {
        return {"id": doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();

      final attendanceDoc =
          await _firestore.collection('attendance').doc(date).get();
      setState(() {
        if (attendanceDoc.exists) {
          _attendance = Map<String, String>.from(attendanceDoc.data()!);
        } else {
          _attendance = {
            for (var student in _students) student['id']: 'not marked'
          };
        }
      });
    } catch (e) {
      print("Error fetching attendance data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isWithinAttendanceTime() {
    return true;
  }

  Future<void> _updateAttendance(String studentId, String status) async {
    if (!_isWithinAttendanceTime()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Attendance can only be changed between 9 AM - 5 PM.")),
      );
      return;
    }

    try {
      _attendance[studentId] = status;
      await _firestore
          .collection('attendance')
          .doc(_selectedDate)
          .set(_attendance);
      setState(() {});
    } catch (e) {
      print("Error updating attendance: $e");
    }
  }

  void _onDateSelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
      _showCalendar = false;
    });
    _fetchStudentsAndAttendance(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: AppDrawer(
        onSelectPage: (Widget) {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calendar Icon + Selected Date
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showCalendar = !_showCalendar;
                              });
                            },
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.blue,
                                  Colors.purple
                                ], // Gradient colors
                              ).createShader(bounds),
                              child: Icon(
                                Icons.calendar_today,
                                size: 24, // Icon size
                                color: Colors
                                    .white, // The icon itself will use white to show the gradient
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              // Text with gradient underline
                              Text(
                                _selectedDate,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2, // Height of the underline
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue,
                                        Colors.purple
                                      ], // Gradient colors
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                          height: 20), // Space between calendar and next row

                      // Search Box + Dropdown
                      Row(
                        children: [
                          // Search Box
                          Expanded(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue,
                                    Colors.purple
                                  ], // Gradient border
                                ),
                              ),
                              padding: EdgeInsets.all(
                                  2), // Creates the border effect
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by Name, Email',
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 10), // Adjusted spacing
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors
                                      .white, // Ensures input area remains white
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide
                                        .none, // Remove default border
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 14),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                          const SizedBox(
                              width:
                                  10), // Space between search box and dropdown

                          // Class Dropdown
                          Expanded(
                            child: Container(
                              height:
                                  50, // Same height as the search box for alignment
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    10), // Rounded corners to match TextField
                                gradient: LinearGradient(
                                  colors: [Colors.blue, Colors.purple],
                                ),
                              ),
                              padding: EdgeInsets.all(2),
                              child: DropdownButtonFormField<String>(
                                value: selectedClass,
                                items: classList.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value,
                                        style: TextStyle(fontSize: 16)),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedClass = newValue!;
                                  });
                                },
                                isExpanded: true,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                                dropdownColor: Colors.white,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 10),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // Rounded corners to match TextField
                                    borderSide: BorderSide
                                        .none, // Remove the default border from dropdown
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide
                                        .none, // Remove focused border too
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide
                                        .none, // Remove enabled border too
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 40),
                  if (_showCalendar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: TableCalendar(
                        firstDay: DateTime(2000),
                        lastDay: DateTime(2100),
                        focusedDay: DateTime.parse(_selectedDate),
                        calendarFormat: _calendarFormat,
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        selectedDayPredicate: (day) =>
                            _selectedDate ==
                            DateFormat('yyyy-MM-dd').format(day),
                        onDaySelected: _onDateSelected,
                        rowHeight: 30,
                        headerStyle: HeaderStyle(
                          titleCentered: true,
                          titleTextStyle: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          formatButtonVisible: false,
                          leftChevronIcon: const Icon(
                            Icons.chevron_left,
                            size: 24,
                            color: Colors.black,
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right,
                            size: 24,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 50),
                            child: ListView.builder(
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final attendanceStatus =
                                    _attendance[student['id']] ?? 'not marked';
                                if (_searchController.text.isNotEmpty) {
                                  final searchLower =
                                      _searchController.text.toLowerCase();
                                  final studentFullName =
                                      student['fullName']?.toLowerCase() ?? '';
                                  final studentClass = student['class']
                                          ?.toString()
                                          .toLowerCase() ??
                                      '';
                                  final attendanceStatusLower =
                                      attendanceStatus.toLowerCase();
                                  if (!studentFullName.contains(searchLower) &&
                                      !studentClass.contains(searchLower) &&
                                      !attendanceStatusLower
                                          .contains(searchLower)) {
                                    return const SizedBox.shrink();
                                  }
                                }
                                if (selectedClass != "Selecte Class" &&
                                    student['class'] != selectedClass) {
                                  return const SizedBox.shrink();
                                }

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    title: Text(student['fullName'] ?? ''),
                                    subtitle:
                                        Text("Class: ${student['class']}"),
                                    trailing: DropdownButton<String>(
                                      value: ['Present', 'Absent', 'Not Marked']
                                              .contains(attendanceStatus)
                                          ? attendanceStatus
                                          : 'Not Marked', // Ensure value exists in dropdown options
                                      items: ['Present', 'Absent', 'Not Marked']
                                          .map((status) => DropdownMenuItem(
                                                value: status,
                                                child: Text(status),
                                              ))
                                          .toList(),
                                      onChanged: (newStatus) {
                                        if (newStatus != null) {
                                          _updateAttendance(
                                              student['id'], newStatus);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
