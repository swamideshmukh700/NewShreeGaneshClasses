// ignore_for_file: use_key_in_widget_constructors, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shri_ganesh_classes/pages/admin_edit_notices_page.dart';
import 'package:shri_ganesh_classes/pages/app_drawer.dart';

class AdminListNoticePage extends StatefulWidget {
  @override
  _AdminListNoticePageState createState() => _AdminListNoticePageState();
}

class _AdminListNoticePageState extends State<AdminListNoticePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedClass;
  List<String> classList = [];
  Map<String, bool> expandedState = {}; // Track expanded content

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    var classSnapshot = await _firestore.collection('class').get();
    setState(() {
      classList =
          classSnapshot.docs.map((doc) => doc['name'] as String).toList();
      selectedClass = null;
    });
  }

  void _deleteNotice(String noticeId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this notice?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                _firestore.collection('notices').doc(noticeId).delete();
                Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(onSelectPage: (Widget) {}),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
              padding: EdgeInsets.all(2),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                value: selectedClass,
                hint: const Text("Select Class"),
                onChanged: (value) {
                  setState(() {
                    selectedClass = value;
                  });
                },
                items: classList.map((className) {
                  return DropdownMenuItem(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedClass == null
                    ? _firestore
                        .collection('notices')
                        .orderBy('date', descending: true)
                        .orderBy(FieldPath.documentId, descending: true)
                        .snapshots()
                    : _firestore
                        .collection('notices')
                        .where('class', isEqualTo: selectedClass)
                        .orderBy('date', descending: true)
                        .orderBy(FieldPath.documentId, descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No notices available for this class."),
                    );
                  }

                  var notice = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: notice.length,
                    itemBuilder: (context, index) {
                      var not = notice[index];
                      String title = not['title'];
                      String content = not['content'];

                      bool isExpanded = expandedState[not.id] ?? false;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: const Color.fromARGB(255, 241, 239, 239),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.green),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AdminUpdateNoticePage(
                                                noticeId: not.id,
                                                title: title,
                                                content: content,
                                                noticeClass: not['class'],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          _deleteNotice(not.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: isExpanded
                                    ? null
                                    : 30, // Fixed height (30px)
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text(
                                    content,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              if (content.length >
                                  30) // Show toggle button only if content exceeds 30px
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        expandedState[not.id] = !isExpanded;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
