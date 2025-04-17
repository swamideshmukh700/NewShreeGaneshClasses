// ignore_for_file: use_build_context_synchronously, avoid_print, unnecessary_string_interpolations

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddFeesPage extends StatefulWidget {
  const AdminAddFeesPage({super.key});

  @override
  _AdminAddFeesPageState createState() => _AdminAddFeesPageState();
}

class _AdminAddFeesPageState extends State<AdminAddFeesPage> {
  final TextEditingController _feesNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _balanceAmountController =
      TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();
  bool _isLoading = false;
  String? _selectedClass;
  String? _selectedStudent;
  List<String> classList = [];
  List<String> studentList = [];

  final CollectionReference classCollection =
      FirebaseFirestore.instance.collection('class');
  final CollectionReference studentCollection =
      FirebaseFirestore.instance.collection('students');
  final CollectionReference feesCollection =
      FirebaseFirestore.instance.collection('fees');

  @override
  void initState() {
    super.initState();
    fetchClass();
    _amountController.addListener(updateBalanceAmount);
    _paidAmountController.addListener(updateBalanceAmount);
  }

  @override
  void dispose() {
    _feesNameController.dispose();
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
        _selectedStudent = null;
      });
    } catch (e) {
      print("Error fetching students: $e");
    }
  }

  void updateBalanceAmount() {
    int totalAmount = int.tryParse(_amountController.text) ?? 0;
    int paidAmount = int.tryParse(_paidAmountController.text) ?? 0;
    int balanceAmount = totalAmount - paidAmount;
    _balanceAmountController.text = balanceAmount.toString();
  }

  void addFees() {
    setState(() {
      _isLoading = true;
    });
    if (_feesNameController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _selectedClass != null &&
        _selectedStudent != null &&
        _paymentDateController.text.isNotEmpty) {
      int totalAmount = int.tryParse(_amountController.text) ?? 0;
      int paidAmount = int.tryParse(_paidAmountController.text) ?? 0;
      int balanceAmount = totalAmount - paidAmount;

      feesCollection.add({
        'feesType': _feesNameController.text,
        'class': _selectedClass,
        'studentName': _selectedStudent,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'balanceAmount': balanceAmount,
        'paymentDate': _paymentDateController.text,
        "paymentHistory": FieldValue.arrayUnion([
          {
            "paidAmount": paidAmount,
            "balanceAmount": balanceAmount, // Store balance amount
            "paymentDate": _paymentDateController.text,
          }
        ]),
      }).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fees added successfully!')));
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error adding fees: $error')));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')));
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Important for keyboard adjustments

      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Add Fees',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Container(
              width: screenWidth < 400 ? screenWidth * 0.85 : 350,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextField(
                    controller: _feesNameController,
                    decoration: InputDecoration(
                      labelText: 'Fees Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Total Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _paidAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Paid Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _balanceAmountController,
                    decoration: InputDecoration(
                      labelText: 'Balance Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    readOnly: true, // हे इनपुट फील्ड Read-Only ठेवले आहे
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedClass = newValue;
                        fetchStudents(newValue!);
                      });
                    },
                    items: classList
                        .map((String className) => DropdownMenuItem<String>(
                            value: className, child: Text(className)))
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedStudent,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedStudent = newValue;
                      });
                    },
                    items: studentList
                        .map((String studentName) => DropdownMenuItem<String>(
                            value: studentName, child: Text(studentName)))
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Student Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _paymentDateController,
                    decoration: InputDecoration(
                      labelText: 'Payment Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      setState(() {
                        _paymentDateController.text =
                            "${pickedDate?.toLocal().toString().split(' ')[0] ?? ''}";
                      });
                    },
                  ),
                  const SizedBox(height: 20),
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
                          onPressed: _isLoading ? null : addFees,
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
                                      'Add Fees',
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
      ),
    );
  }
}
