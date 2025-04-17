// ignore_for_file: avoid_print, unused_local_variable, unused_element, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shri_ganesh_classes/pages/login_page.dart';
// import 'package:shri_ganesh_classes/pages/user_test_list_page.dart';
// import 'package:shri_ganesh_classes/pages/user_view_attendance.dart';
import 'package:shri_ganesh_classes/widgets/bottom_navigation.dart';
import 'package:shri_ganesh_classes/widgets/custom_app_bar.dart';

class UserViewFees extends StatefulWidget {
  final String studentEmail;
  final String studentId; //  Add these as final variables
  final String studentClass;

  const UserViewFees({
    super.key,
    required this.studentEmail,
    required this.studentId, //  Now properly stored
    required this.studentClass,
    required String firstName,
    required String email, //  Now properly stored
  });

  @override
  _UserViewFeesState createState() => _UserViewFeesState();
}

class _UserViewFeesState extends State<UserViewFees> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Add scaffold key

  String? studentClass;
  bool isLoading = true;
  List<Map<String, dynamic>> fees = [];
  Set<String> expandedNotes = {};
  List<Map<String, dynamic>> filteredFees = [];
  String searchQuery = "";
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchStudentClassAndFees();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentClassAndFees() async {
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

        // Fetch
        QuerySnapshot feesQuery = await FirebaseFirestore.instance
            .collection('fees')
            .where('class', isEqualTo: studentClass)
            .get();

        List<Map<String, dynamic>> fetcheFees = feesQuery.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return {
            'feesType': data['feesType'], // Keep existing data
            'class': data['class'],
            'studentName': data['studentName'], // Removed extra space
            'totalAmount': data['totalAmount'],
            'paidAmount': data['paidAmount'],
            'balanceAmount': data['balanceAmount'],
            'paymentHistory': data['paymentHistory'] != null
                ? List<Map<String, dynamic>>.from(data['paymentHistory'])
                : [],

            'paymentDate': data['paymentDate'] is Timestamp
                ? (data['paymentDate'] as Timestamp).toDate()
                : (data['paymentDate'] != null &&
                        data['paymentDate'].toString().isNotEmpty
                    ? DateTime.parse(data['paymentDate'])
                    : null), // Null check for paymentDate
          };
        }).toList();

// 🔹 Sorting Notes by Date (Latest First)
        fetcheFees.sort((a, b) => b['paymentDate'].compareTo(a['paymentDate']));

        setState(() {
          fees = fetcheFees;
          filteredFees = fetcheFees;
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
        title: "Payment History ",
        scaffoldKey: _scaffoldKey,
        email: widget.studentEmail,
        onLogout: () {},
      ),

      bottomNavigationBar: BottomNavigation(
        email: widget.studentEmail,
        studentId: widget.studentId,
        selectedIndex: 5, // Change based on the current page
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filteredFees.isEmpty
                      ? const Center(
                          child: Text(
                            "No fees history found",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredFees.length,
                          itemBuilder: (context, index) {
                            var fee = filteredFees[index];

                            // Check if paymentHistory exists and is a List
                            List<dynamic> paymentHistory =
                                (fee['paymentHistory'] ?? []) as List<dynamic>;

                            return Card(
                              margin: const EdgeInsets.all(5),
                              elevation: 4,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                title: Text(
                                  "${fee['feesType']}",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total: ₹${fee['totalAmount']} | "
                                      "Paid: ₹${fee['paidAmount']} | "
                                      "Balance: ₹${fee['balanceAmount']}",
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Payment History:",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: paymentHistory.map((payment) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2),
                                          child: Text(
                                            "• Paid: ₹${payment['paidAmount']} | "
                                            "Balance: ₹${payment['balanceAmount']} | "
                                            "Date: ${payment['paymentDate']}",
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
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
