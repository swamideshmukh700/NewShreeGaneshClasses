// ignore_for_file: use_super_parameters, unused_field, use_build_context_synchronously, avoid_print, deprecated_member_use, unused_local_variable, unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminEditFeesPage extends StatefulWidget {
  final String feeId;

  const AdminEditFeesPage({Key? key, required this.feeId}) : super(key: key);

  @override
  _AdminEditFeesPageState createState() => _AdminEditFeesPageState();
}

class _AdminEditFeesPageState extends State<AdminEditFeesPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _feesTypeController;
  late TextEditingController _amountController;
  late TextEditingController _paidAmountController;
  late TextEditingController _balanceAmountController;
  late TextEditingController _paymentDateController;

  bool _isLoading = false;
  String? _selectedClass;
  String? _selectedStudent;
  List<String> classList = [];
  List<String> studentList = [];

  final CollectionReference classCollection =
      FirebaseFirestore.instance.collection('class');
  final CollectionReference studentCollection =
      FirebaseFirestore.instance.collection('students');

  @override
  void initState() {
    super.initState();
    print("Fee ID: ${widget.feeId}");

    _feesTypeController = TextEditingController();
    _amountController = TextEditingController();
    _paidAmountController = TextEditingController();

    _balanceAmountController = TextEditingController();
    _paymentDateController = TextEditingController();

    fetchClass();
    _loadFeesData();
  }

  void _loadFeesData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('fees')
          .doc(widget.feeId)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        print("No data found for this fee ID: ${widget.feeId}");
        return;
      }

      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      // print("Fetched data: $data");

      if (data != null) {
        setState(() {
          _feesTypeController.text = data['feesType'] ?? '';
          _amountController.text = (data['totalAmount'] != null)
              ? data['totalAmount'].toString()
              : '0';

          _paymentDateController.text = data['paymentDate'] ?? '';
          _selectedClass = data['class'] ?? '';
          _selectedStudent = data['studentName'] ?? '';
        });
      }
    } catch (e, stacktrace) {
      print('🔥 Error loading fee data: $e');
      print(stacktrace);
    }
  }

  @override
  void dispose() {
    _feesTypeController.dispose();
    _amountController.dispose();
    _paidAmountController.dispose();
    _balanceAmountController.dispose();
    _paymentDateController.dispose();
    super.dispose();
  }

  void fetchClass() async {
    try {
      QuerySnapshot snapshot = await classCollection.get();
      setState(() {
        classList = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      print("Error fetching class: $e");
    }
  }

  void fetchStudents(String selectedClass) async {
    try {
      QuerySnapshot snapshot = await studentCollection
          .where('class', isEqualTo: selectedClass)
          .get();
      setState(() {
        studentList =
            snapshot.docs.map((doc) => doc['fullName'] as String).toList();
        if (studentList.isNotEmpty) {
          _selectedStudent = studentList.first; // पहिला विद्यार्थी निवडा
        }
      });
    } catch (e) {
      print("Error fetching students: $e");
    }
  }

  void updateBalanceAmount() {
    int totalAmount = int.tryParse(_amountController.text) ?? 0;
    int paidAmount = int.tryParse(_paidAmountController.text) ?? 0;
    int balanceAmount = totalAmount - paidAmount;

    setState(() {
      _balanceAmountController.text = balanceAmount.toString();
    });
  }

  Future<void> _updateFee() async {
    try {
      DocumentReference feeDocRef =
          FirebaseFirestore.instance.collection('fees').doc(widget.feeId);

      // **Firestore Document Fetch करा**
      DocumentSnapshot snapshot = await feeDocRef.get();

      if (snapshot.exists) {
        // **Firestore मध्ये अपडेट करा**
        await feeDocRef.update({
          'feesType': _feesTypeController.text,
          'class': _selectedClass,
          'studentName': _selectedStudent,
          'paymentDate': _paymentDateController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fees updated successfully!")),
        );
        Navigator.pop(context);
      } else {
        print("Document does not exist!");
      }
    } catch (e) {
      print("Error updating fee: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update fees')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Update Fees',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width > 400
                ? 400
                : MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Fee Type
                TextFormField(
                  controller: _feesTypeController,
                  decoration: const InputDecoration(
                      labelText: "Fee Type", border: OutlineInputBorder()),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a fee name" : null,
                ),
                const SizedBox(height: 16),

                // Class Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: "Select Class",
                    border: OutlineInputBorder(),
                  ),
                  items: classList.map((className) {
                    return DropdownMenuItem(
                      value: className,
                      child: Text(className),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                      fetchStudents(
                          value!); // नव्या क्लाससाठी स्टुडंट्स लोड करायचे
                    });
                  },
                  validator: (value) =>
                      value == null ? "Please select a class" : null,
                ),
                const SizedBox(height: 16),

                // Student Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedStudent,
                  decoration: const InputDecoration(
                    labelText: "Select Student",
                    border: OutlineInputBorder(),
                  ),
                  items: studentList.map((studentName) {
                    return DropdownMenuItem(
                      value: studentName,
                      child: Text(studentName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStudent = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? "Please select a student" : null,
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Amount", border: OutlineInputBorder()),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter an amount" : null,
                  onChanged: (value) => updateBalanceAmount(),
                ),
                const SizedBox(height: 16),

                // Paid Amount

                // Balance Amount (Read-only)

                const SizedBox(height: 16),

                // Due Date
                TextFormField(
                  controller: _paymentDateController,
                  decoration: const InputDecoration(
                      labelText: "payment Date", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                // Update Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 130,
                      height: 70,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(12),
                          foregroundColor: Colors.white,
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => Colors.transparent,
                          ),
                          shadowColor:
                              WidgetStateProperty.all(Colors.transparent),
                        ),
                        onPressed: _isLoading ? null : _updateFee,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Update',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
