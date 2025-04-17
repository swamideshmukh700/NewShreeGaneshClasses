// ignore_for_file: avoid_print, use_build_context_synchronously, unused_local_variable
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shri_ganesh_classes/pages/user_test_review_page.dart';

import 'package:shri_ganesh_classes/pages/user_test_questions_page.dart';
import 'package:shri_ganesh_classes/widgets/bottom_navigation.dart';
import 'package:shri_ganesh_classes/widgets/custom_app_bar.dart';

// ignore: must_be_immutable
class UserTestListPage extends StatefulWidget {
  final String studentEmail;
  final String studentId; //  Add this if missing
  final dynamic studentClass; //  Add this if missing
  final String testId;
  final String fullName;

  const UserTestListPage({
    super.key,
    required this.studentEmail,
    required String tests,
    required this.studentId,
    required this.studentClass,
    required this.testId,
    required this.fullName,
  });

  @override
  _UserTestListPageState createState() => _UserTestListPageState();
}

class _UserTestListPageState extends State<UserTestListPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Define scaffold key

  List<Map<String, dynamic>> tests = [];
  bool isLoading = true;
  String? studentId; //  Add studentId variable
  String? studentClass; //  Store student class in state
  late int totalMarks = 0;
  int obtainedMarks = 0;
  @override
  void initState() {
    super.initState();
    fetchTests();
  }

  Future<void> fetchTests() async {
    try {
      setState(() => isLoading = true);

      QuerySnapshot studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: widget.studentEmail)
          .limit(1)
          .get();

      DocumentSnapshot? studentDoc;

      if (studentQuery.docs.isNotEmpty) {
        studentDoc = studentQuery.docs.first;
      } else {
        studentQuery = await FirebaseFirestore.instance
            .collection('students')
            .where('userName', isEqualTo: widget.studentEmail)
            .limit(1)
            .get();

        if (studentQuery.docs.isNotEmpty) {
          studentDoc = studentQuery.docs.first;
        }
      }

      if (studentDoc == null) {
        print("Student not found");
        setState(() => isLoading = false);
        return;
      }

      var studentData = studentDoc.data() as Map<String, dynamic>;
      String userName = studentData['userName'] ?? 'Unknown';
      String studentClass = studentData['class']?.toString().trim() ?? '';

      setState(() {
        this.studentClass = studentClass;
      });

      QuerySnapshot testDocs = await FirebaseFirestore.instance
          .collection('tests')
          .where('class', isEqualTo: studentClass)
          .get();

      List<Map<String, dynamic>> fetchedTests = [];

      for (var doc in testDocs.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String testId = doc.id;

        QuerySnapshot attemptDocs = await FirebaseFirestore.instance
            .collection('test_attempts')
            .where('testId', isEqualTo: testId)
            .where('email', isEqualTo: widget.studentEmail)
            .get();

        bool isAttended = attemptDocs.docs.isNotEmpty;
        String yourScore = isAttended
            ? (attemptDocs.docs.first['yourScore'] ?? '00').toString()
            : '00'; // Prevent Bad state error

        fetchedTests.add({
          "id": testId,
          "name": data['name'] ?? 'Unnamed Test',
          "totalMarks": data['totalMarks'] ?? 'N/A',
          "setTime": data['setTime'] ?? '0',
          "testDate": data['testDate'] ?? 'N/A',
          "testTime": data['testTime'] ?? 'N/A',
          "durationMinutes": data['durationMinutes'] ?? 'N/A',
          'yourScore': yourScore,
          "isAttended": isAttended,
        });
      }

      if (mounted) {
        setState(() {
          tests = fetchedTests;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching tests: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> checkTestAttempt(
    String testId,
    String testName,
    String testDate,
    String testTime,
    dynamic durationMinutes,
  ) async {
    try {
      // Check if the test is already attempted
      QuerySnapshot attemptDocs = await FirebaseFirestore.instance
          .collection('test_attempts')
          .where('testId', isEqualTo: testId)
          .where('email', isEqualTo: widget.studentEmail)
          .get();

      if (testDate.isEmpty || testTime.isEmpty) {
        showErrorDialog("Invalid Test Data", "Test date or time is missing.");
        return;
      }

      if (attemptDocs.docs.isNotEmpty) {
        var attemptData =
            attemptDocs.docs.first.data() as Map<String, dynamic>? ?? {};
        int obtainedMarks =
            int.tryParse(attemptData['yourScore']?.toString() ?? "0") ?? 0;
        int totalMarks =
            int.tryParse(attemptData['totalMarks']?.toString() ?? "0") ?? 0;

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Your test is completed - $testName"),
                content: Text(
                  "You scored $obtainedMarks out of $totalMarks",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestReviewPage(
                            testId: testId,
                            studentEmail: widget.studentEmail,
                          ),
                        ),
                      );
                    },
                    child: const Text("View Answers"),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      DateTime now = DateTime.now();

      // Combine testDate and testTime into DateTime format
      String testDateTimeString = "$testDate $testTime";
      DateTime testStartTime =
          DateFormat('yyyy-MM-dd hh:mm a').parse(testDateTimeString);

      // Convert durationMinutes to an integer (handling int and String types)
      int duration = (durationMinutes is int)
          ? durationMinutes
          : int.tryParse(durationMinutes.toString()) ?? 0;
      DateTime testEndTime = testStartTime.add(Duration(minutes: duration));

      // print(testEndTime);
      if (now.isBefore(testStartTime)) {
        // Test has not started yet
        showErrorDialog("Test Not Started",
            "Test will be available at: ${DateFormat('yyyy-MM-dd hh:mm a').format(testStartTime)}");
      } else if (now.isAfter(testEndTime)) {
        // Test has already ended
        showErrorDialog("Test Closed",
            "Expired Test at: ${DateFormat('yyyy-MM-dd hh:mm a').format(testEndTime)}");
      } else {
        // Test is currently available
        // Step 1: fullName Firebase मधून मिळव
        String userFullName = '';

        QuerySnapshot studentQuery = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: widget.studentEmail)
            .limit(1)
            .get();

        if (studentQuery.docs.isNotEmpty) {
          userFullName = studentQuery.docs.first['fullName'];
        }

// Step 2: Check if context is still mounted before navigation
        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserTestQuestionsPage(
                testId: testId,
                studentEmail: widget.studentEmail,
                fullName: userFullName, // ✅ Firebase मधून घेतलेलं नाव वापर
                studentId: '',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(
            "Error", "An error occurred while checking the test status.");
      }
    }
  }

// Function to Show Error Message in App Dialog
  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title), // 👈 Dynamic title
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //  Define the _buildDrawerItem method
  // ignore: unused_element
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 146, 58, 218)),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign key to Scaffold
      appBar: CustomAppBar(
        title: "View Test",
        scaffoldKey: _scaffoldKey,
        email: widget.studentEmail,
        onLogout: () {},
      ),

      bottomNavigationBar: BottomNavigation(
        email: widget.studentEmail,
        studentId: widget.studentId,
        selectedIndex: 1, // Change based on the current page
      ),

      backgroundColor: Colors.grey[200],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tests.isEmpty
              ? const Center(
                  child: Text(
                    'No tests available for your class',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.builder(
                    itemCount: tests.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => checkTestAttempt(
                          tests[index]['id'],
                          tests[index]['name'],
                          tests[index]['testDate'],
                          tests[index]['testTime'],
                          tests[index]['durationMinutes'],
                        ),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Test Name: ${tests[index]['name'] ?? 'N/A'}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Date: ${tests[index]['testDate'] ?? 'N/A'}",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black54),
                                      ),
                                      Text(
                                        "Time: ${tests[index]['testTime'] ?? 'N/A'}",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black54),
                                      ),
                                      Text(
                                        "Duration: ${tests[index]['durationMinutes'] ?? '0'} mins",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  () {
                                    DateTime now = DateTime.now();
                                    DateTime testStartTime =
                                        DateFormat('yyyy-MM-dd hh:mm a').parse(
                                            '${tests[index]['testDate']} ${tests[index]['testTime']}');

                                    int duration = int.tryParse(tests[index]
                                                ['durationMinutes']
                                            .toString()) ??
                                        0;
                                    DateTime testEndTime = testStartTime
                                        .add(Duration(minutes: duration));

                                    if (tests[index]['isAttended']) {
                                      return 'Completed Test\n${tests[index]['yourScore'] ?? 0}/${tests[index]['totalMarks'] ?? 0} Marks';
                                    } else if (now.isBefore(testStartTime)) {
                                      return 'Upcoming Test\n${tests[index]['totalMarks']} Marks';
                                    } else if (now.isAfter(testEndTime)) {
                                      return 'Expired Test';
                                    } else {
                                      return 'Ongoing Test';
                                    }
                                  }(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: (tests[index]['isAttended']
                                        ? Colors.green
                                        : DateTime.now().isBefore(
                                                DateFormat('yyyy-MM-dd hh:mm a')
                                                    .parse(
                                                        '${tests[index]['testDate']} ${tests[index]['testTime']}'))
                                            ? Colors
                                                .orange // Upcoming test color
                                            : (DateTime.now().isAfter(DateFormat(
                                                        'yyyy-MM-dd hh:mm a')
                                                    .parse(
                                                        '${tests[index]['testDate']} ${tests[index]['testTime']}')
                                                    .add(Duration(
                                                        minutes: int.tryParse(
                                                                tests[index]
                                                                        ['durationMinutes']
                                                                    .toString()) ??
                                                            0))))
                                                ? Colors.red // Expired test color
                                                : Colors.blue) as Color?, // 🛠 **EXPLICIT CASTING**
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
