// ignore_for_file: non_constant_identifier_names, unused_label, prefer_final_fields, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shri_ganesh_classes/pages/admin_edit_test_page.dart';
import 'package:shri_ganesh_classes/pages/admin_list_question.dart';
// import 'package:shri_ganesh_classes/pages/admin_list_question.dart';
import 'package:shri_ganesh_classes/pages/admin_test_review_page.dart';
import 'package:shri_ganesh_classes/pages/app_drawer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class AdminTestManagementPage extends StatefulWidget {
  const AdminTestManagementPage({super.key});

  @override
  _AdminTestManagementPageState createState() =>
      _AdminTestManagementPageState();
}

class _AdminTestManagementPageState extends State<AdminTestManagementPage> {
  String searchQuery = "";
  String? selectedClass;
  List<String> classList = ["Selecte Class"];
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

void getToken() async {
  String? token = await _firebaseMessaging.getToken();
  print("FCM Token: $token");
}

  Future<void> _fetchClasses() async {
    var classSnapshot = await _firestore.collection('class').get();
    setState(() {
      classList.addAll(
          classSnapshot.docs.map((doc) => doc['name'] as String).toList());
      selectedClass = "Selecte Class";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        onSelectPage: (Widget) {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Search Field
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple], // Gradient border
                    ),
                  ),
                  padding: EdgeInsets.all(2), // Creates the border effect
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search Test',
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                ),

                // Dropdown Field
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple], // Gradient border
                    ),
                  ),
                  padding: EdgeInsets.all(2), // Creates the border effect
                  child: DropdownButtonFormField<String>(
                    value: selectedClass,
                    hint: Text("Select Class"),
                    items: classList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedClass = newValue!;
                      });
                    },
                    isExpanded: true,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    menuMaxHeight: 200,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('tests')
                    .orderBy('testDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  var tests = snapshot.data!.docs.where((test) {
                    var testData = test.data() as Map<String, dynamic>;
                    var testName = testData['name']?.toLowerCase() ?? "";
                    var testClass = testData['class'] ?? "";

                    bool matchesSearch =
                        searchQuery.isEmpty || testName.contains(searchQuery);
                    bool matchesClass = selectedClass == null ||
                        selectedClass == "Selecte Class" ||
                        testClass == selectedClass;

                    return matchesSearch && matchesClass;
                  }).toList();

                  return ListView.builder(
                    itemCount: tests.length,
                    itemBuilder: (context, index) {
                      var test = tests[index];
                      Map<String, dynamic> testData =
                          test.data() as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () {
                          // Test var click kelyavr question page open hoil
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminQuestionListPage(
                                testId: test.id,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          color: Colors.grey[200],
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: Title and Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(testData['name'] ?? 'No Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4),
                                      Text(
                                        'Class: ${testData['class'] ?? 'N/A'} | Marks: ${testData['totalMarks'] ?? 0}\n'
                                        'Date: ${testData['testDate'] ?? 'No Date'} | Time: ${testData['testTime'] ?? 'No Time'}\n'
                                        'Duration: ${testData['durationMinutes'] ?? 0} min',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right: All 3 icons one below the other
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    FutureBuilder<QuerySnapshot>(
                                      future: _firestore
                                          .collection('test_attempts')
                                          .where('testId', isEqualTo: test.id)
                                          .limit(1)
                                          .get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return SizedBox(height: 30);
                                        }
                                        if (snapshot.hasData &&
                                            snapshot.data!.docs.isNotEmpty) {
                                          return IconButton(
                                            icon: Icon(Icons.remove_red_eye,
                                                color: Colors.blue, size: 20),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AdminTestReviewPage(
                                                          testId: test.id),
                                                ),
                                              );
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          );
                                        } else {
                                          return SizedBox(height: 30);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: Colors.green, size: 20),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AdminEditTestPage(
                                              testId: test.id,
                                              testName: testData['name'],
                                              testClass: testData['class'],
                                              totalMarks:
                                                  testData['totalMarks'],
                                              durationMinutes:
                                                  testData['durationMinutes'],
                                              testDate: testData['testDate'],
                                              testTime: testData['testTime'],
                                            ),
                                          ),
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.red, size: 20),
                                      onPressed: () {
                                        _firestore
                                            .collection('tests')
                                            .doc(test.id)
                                            .delete();
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
