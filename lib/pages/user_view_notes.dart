// ignore_for_file: avoid_print, unused_local_variable, unused_element, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shri_ganesh_classes/pages/login_page.dart';
// import 'package:shri_ganesh_classes/pages/user_test_list_page.dart';
// import 'package:shri_ganesh_classes/pages/user_view_attendance.dart';
import 'package:shri_ganesh_classes/widgets/bottom_navigation.dart';
import 'package:shri_ganesh_classes/widgets/custom_app_bar.dart';

class UserViewNotes extends StatefulWidget {
  final String studentEmail;
  final String studentId; //  Add these as final variables
  final String studentClass;

  const UserViewNotes({
    super.key,
    required this.studentEmail,
    required this.studentId, //  Now properly stored
    required this.studentClass,
    required String firstName,
    required String email, //  Now properly stored
  });

  @override
  _UserViewNotesState createState() => _UserViewNotesState();
}

class _UserViewNotesState extends State<UserViewNotes> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Add scaffold key

  String? studentClass;
  bool isLoading = true;
  List<Map<String, dynamic>> notes = [];
  Set<String> expandedNotes = {};
  List<Map<String, dynamic>> filteredNotes = [];
  String searchQuery = "";
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchStudentClassAndNotes();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentClassAndNotes() async {
    try {
      QuerySnapshot studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: widget.studentEmail)
          .limit(1)
          .get();
      if (studentQuery.docs.isEmpty) {
        // Try fetching by userName instead
        studentQuery = await FirebaseFirestore.instance
            .collection('students')
            .where('userName', isEqualTo: widget.studentEmail)
            .limit(1)
            .get();
      }

      if (studentQuery.docs.isNotEmpty) {
        var studentData =
            studentQuery.docs.first.data() as Map<String, dynamic>;

        String studentClass = studentData['class']?.toString().trim() ?? '';

        setState(() {
          this.studentClass = studentClass;
        });

        if (studentClass.isEmpty) {
          setState(() => isLoading = false);
          return;
        }

        // Fetch notes
        QuerySnapshot notesQuery = await FirebaseFirestore.instance
            .collection('notes')
            .where('class', isEqualTo: studentClass)
            .get();
        List<Map<String, dynamic>> fetchedNotes = notesQuery.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return {
            'title': data['title'],
            'content': data['content'],
            'date': data['date'] is Timestamp
                ? (data['date'] as Timestamp)
                    .toDate() // Convert Firestore Timestamp to DateTime
                : DateTime.parse(data[
                    'date']), // Convert String date (yyyy-MM-dd) to DateTime
            'id': doc.id,
            'expanded': false,
          };
        }).toList();

// 🔹 Sorting Notes by Date (Latest First)
        fetchedNotes.sort((a, b) => b['date'].compareTo(a['date']));

        setState(() {
          notes = fetchedNotes;
          filteredNotes = fetchedNotes;
          isLoading = false;
        });
      } else {
        print('No student found with this email or userName');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  void _searchNotes(String query) {
    setState(() {
      searchQuery = query;
      filteredNotes = notes
          .where((note) =>
              note['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// 🔹 Function to Build Drawer Item
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign key to Scaffold
      appBar: CustomAppBar(
        title: "View Notes",
        scaffoldKey: _scaffoldKey,
        email: widget.studentEmail,
        onLogout: () {},
      ),

      // drawer: Drawer(
      //   child: Column(
      //     children: [
      //       // Drawer Header
      //       Container(
      //         width: double.infinity,
      //         padding: const EdgeInsets.all(20),
      //         decoration: const BoxDecoration(
      //           gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
      //           borderRadius: BorderRadius.only(
      //             bottomLeft: Radius.circular(20),
      //             bottomRight: Radius.circular(20),
      //           ),
      //         ),
      //         child: Column(
      //           children: [
      //             const CircleAvatar(
      //               radius: 40,
      //               backgroundColor: Colors.white,
      //               child: Icon(Icons.account_circle,
      //                   size: 50, color: Colors.blue),
      //             ),
      //             const SizedBox(height: 10),
      //             Text(
      //               widget.studentEmail, //  Fixed variable name
      //               style: const TextStyle(
      //                   color: Colors.white,
      //                   fontWeight: FontWeight.bold,
      //                   fontSize: 16),
      //             ),
      //             Text(
      //               "Class: $studentClass", //  Fixed studentClass reference
      //               style: const TextStyle(color: Colors.white, fontSize: 14),
      //             ),
      //           ],
      //         ),
      //       ),

      //       const SizedBox(height: 10),

      //       // Drawer Items
      //       _buildDrawerItem(Icons.assignment, "View Test", () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //             builder: (context) => UserTestListPage(
      //               studentEmail: widget.studentEmail, tests: '',
      //               studentId: widget.studentId, // Ensure it's not null
      //               studentClass: studentClass ?? '', //  Fixed variable name
      //             ),
      //           ),
      //         );
      //       }),

      //       _buildDrawerItem(Icons.book, "View Notes", () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //             builder: (context) => UserViewNotes(
      //               studentEmail: widget.studentEmail,
      //               studentId: widget.studentId, // Ensure it's not null
      //               studentClass: studentClass ?? '', firstName: '',
      //               email: '', //  Fixed variable name
      //             ),
      //           ),
      //         );
      //       }),

      //       _buildDrawerItem(Icons.event_available, "View Attendance", () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //             builder: (context) => UserViewAttendance(
      //               studentEmail: widget.studentEmail,
      //               studentId: widget.studentId, // Ensure it's not null
      //               studentClass: studentClass ?? '', //  Fixed variable name
      //             ),
      //           ),
      //         );
      //       }),

      //       const Spacer(),

      //       // Logout Button
      //       ListTile(
      //         leading: ShaderMask(
      //           shaderCallback: (bounds) => const LinearGradient(
      //             colors: [Colors.blue, Colors.purple],
      //           ).createShader(bounds),
      //           child:
      //               const Icon(Icons.exit_to_app_rounded, color: Colors.white),
      //         ),
      //         title: ShaderMask(
      //           shaderCallback: (bounds) => const LinearGradient(
      //             colors: [Colors.blue, Colors.purple],
      //           ).createShader(bounds),
      //           child:
      //               const Text('Logout', style: TextStyle(color: Colors.white)),
      //         ),
      //         onTap: () {
      //           Navigator.pushAndRemoveUntil(
      //             context,
      //             MaterialPageRoute(builder: (context) => const LoginPage()),
      //             (route) => false,
      //           );
      //         },
      //       )
      //     ],
      //   ),
      // ),

      bottomNavigationBar: BottomNavigation(
        email: widget.studentEmail,
        studentId: widget.studentId,
        selectedIndex: 2, // Change based on the current page
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    onChanged: _searchNotes,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Search notes...",
                      hintStyle: const TextStyle(fontSize: 16),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 13, 13, 14), width: 2.0),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filteredNotes.isEmpty
                      ? const Center(
                          child: Text(
                            "No notes found",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            var note = filteredNotes[index];
                            bool isExpanded =
                                expandedNotes.contains(note['id']);
                            List<String> words = note['content'].split(' ');
                            bool isLong = words.length > 20;
                            return Card(
                              margin: const EdgeInsets.all(5),
                              elevation: 4,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                title: Text(
                                  note['title'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final textSpan = TextSpan(
                                      text: note['content'],
                                      style: const TextStyle(fontSize: 16),
                                    );
                                    final textPainter = TextPainter(
                                      text: textSpan,
                                      maxLines: 1,
                                      textDirection: TextDirection.ltr,
                                    );
                                    textPainter.layout(
                                        maxWidth: constraints.maxWidth);

                                    bool isOverflowing =
                                        textPainter.didExceedMaxLines;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          constraints: BoxConstraints(
                                            maxHeight: note['expanded']
                                                ? double.maxFinite
                                                : 30, // Fix
                                          ),
                                          child: Text(
                                            note['content'],
                                            style:
                                                const TextStyle(fontSize: 16),
                                            maxLines:
                                                note['expanded'] ? null : 1,
                                            overflow: note['expanded']
                                                ? TextOverflow.visible
                                                : TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isOverflowing) // फक्त Overflow असलेल्या Text साठी Show करणार
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                note['expanded'] =
                                                    !note['expanded'];
                                              });
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 5),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Icon(
                                                    note['expanded']
                                                        ? Icons.arrow_upward
                                                        : Icons.arrow_downward,
                                                    color: Colors.blue,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
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
