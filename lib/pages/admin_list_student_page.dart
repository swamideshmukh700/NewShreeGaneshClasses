// ignore_for_file: library_private_types_in_public_api, non_constant_identifier_names, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shri_ganesh_classes/pages/app_drawer.dart';
import 'package:shri_ganesh_classes/pages/admin_edit_student_page.dart';

class AdminListStudentPage extends StatefulWidget {
  const AdminListStudentPage({super.key});

  @override
  _AdminListStudentPageState createState() => _AdminListStudentPageState();
}

// ... तुमचं बाकी import तसंच राहू द्या

class _AdminListStudentPageState extends State<AdminListStudentPage> {
  String searchQuery = "";
  String? selectedClass = "Selecte Class";
  List<String> classList = ["Selecte Class"];
  Map<String, int> classCounts = {};
  int totalStudents = 0;

  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Stream<QuerySnapshot> studentsStream =
      FirebaseFirestore.instance.collection('students').snapshots();

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _fetchStudentCounts();
  }

  Future<void> _fetchClasses() async {
    var classSnapshot = await _firestore.collection('class').get();
    setState(() {
      classList.addAll(
          classSnapshot.docs.map((doc) => doc['name'] as String).toList());
    });
  }

  Future<void> _fetchStudentCounts() async {
    var snapshot = await _firestore.collection('students').get();
    Map<String, int> counts = {};
    int total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final className = data['class'] ?? 'Unknown';
      counts[className] = (counts[className] ?? 0) + 1;
      total++;
    }
    setState(() {
      classCounts = counts;
      totalStudents = total;
    });
  }

  void deleteUser(String id) async {
    await FirebaseFirestore.instance.collection('students').doc(id).delete();
    _fetchStudentCounts();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student deleted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    String countText;
    if (selectedClass == "Selecte Class") {
      countText = "Total Students: $totalStudents";
    } else {
      countText =
          "$selectedClass Class Students: ${classCounts[selectedClass] ?? 0}";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(onSelectPage: (Widget) {}),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// ✅ TOP STUDENT COUNT TEXT
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.blue], // हे दोन रंग
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                countText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),

            /// 🔍 Search + Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Search Field
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Email',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
                      prefixIcon: const Icon(Icons.search),
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
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),

                // Dropdown
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.purple]),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: DropdownButtonFormField<String>(
                    value: selectedClass,
                    items: classList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child:
                            Text(value, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedClass = newValue!;
                      });
                    },
                    isExpanded: true,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
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
            const SizedBox(height: 10),

            /// Student Table (as-is तुमचं)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: studentsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }

                  String search = searchQuery.toLowerCase();

                  final List<Map<String, dynamic>> storedocs =
                      snapshot.data!.docs
                          .map((doc) => {
                                ...doc.data() as Map<String, dynamic>,
                                'id': doc.id,
                              })
                          .where((student) {
                    bool matchesSearch =
                        (student['fullName']?.toString().toLowerCase() ?? '')
                                .contains(search) ||
                            (student['email']?.toLowerCase() ?? '')
                                .contains(search);

                    bool matchesClass = selectedClass == "Selecte Class" ||
                        student['class'] == selectedClass;

                    return matchesSearch && matchesClass;
                  }).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 600),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columnSpacing: 40.0,
                          headingRowColor: WidgetStateColor.resolveWith(
                              (states) => Colors.grey.shade300),
                          columns: const [
                            DataColumn(label: Text('Actions')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('User Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Class')),
                            DataColumn(label: Text('Password')),
                          ],
                          rows: storedocs.map((student) {
                            return DataRow(cells: [
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.green),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminEditStudentPage(
                                            studentId: student['id'],
                                            id: null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    onPressed: () => deleteUser(student['id']),
                                  ),
                                ],
                              )),
                              DataCell(Text(student['fullName'] ?? 'No Name')),
                              DataCell(
                                  Text(student['userName'] ?? 'No User Name')),
                              DataCell(Text(student['email'] ?? 'No Email')),
                              DataCell(Text(student['class'] ?? 'No Class')),
                              DataCell(
                                  Text(student['password'] ?? 'No Password')),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
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
