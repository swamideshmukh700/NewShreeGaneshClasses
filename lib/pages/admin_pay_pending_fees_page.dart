// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminPayPendingFeesPage extends StatefulWidget {
  final String feeId;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String studentName;
  final String className;
  final String feesType;
  final String paymentDate;

  const AdminPayPendingFeesPage({
    super.key,
    required this.feeId,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.studentName,
    required this.className,
    required this.feesType,
    required this.paymentDate,
  });

  @override
  _AdminPayPendingFeesPageState createState() =>
      _AdminPayPendingFeesPageState();
}

class _AdminPayPendingFeesPageState extends State<AdminPayPendingFeesPage> {
  late double totalAmount;
  late double paidAmount;
  late double balanceAmount;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    totalAmount = widget.totalAmount;
    paidAmount = widget.paidAmount;
    balanceAmount = widget.balanceAmount;
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
   
    if (picked != null) {
  setState(() {
    _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
  });
}

    }

  Future<void> payFees() async {
    double newPaidAmount = double.tryParse(_amountController.text) ?? 0;
    String selectedDate = _dateController.text;

    if (newPaidAmount <= 0 || newPaidAmount > balanceAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid amount!")),
      );
      return;
    }

    if (selectedDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a date!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      DocumentReference docRef =
          _firestore.collection("fees").doc(widget.feeId);

      // Get the latest data from Firestore
      DocumentSnapshot docSnapshot = await docRef.get();
      Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

      if (data != null) {
        double oldPaidAmount = data["paidAmount"] ?? 0;
        double updatedPaidAmount = oldPaidAmount + newPaidAmount;
        double updatedBalanceAmount =
            (data["totalAmount"] ?? 0) - updatedPaidAmount;

        await docRef.update({
          "paidAmount": updatedPaidAmount,
          "balanceAmount": updatedBalanceAmount,
          "paymentHistory": FieldValue.arrayUnion([
            {
              "paidAmount": newPaidAmount,
              "balanceAmount": updatedBalanceAmount,
              "paymentDate": selectedDate,
            }
          ]),
        });

        setState(() {
          paidAmount = updatedPaidAmount;
          balanceAmount = updatedBalanceAmount;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "₹$newPaidAmount paid successfully! New Balance: ₹$updatedBalanceAmount",
          ),
        ));

        Navigator.pop(context);
        _amountController.clear();
        _dateController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Student: ${widget.studentName}",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Class: ${widget.className}",
                        style: TextStyle(fontSize: 16)),
                    Text("Fees Type: ${widget.feesType}",
                        style: TextStyle(fontSize: 16)),
                    Text("Due Date: ${widget.paymentDate}",
                        style: TextStyle(fontSize: 16, color: Colors.red)),
                    SizedBox(height: 20),
                    Text("Total Fees: ₹$totalAmount",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Paid Fees: ₹$paidAmount",
                        style: TextStyle(fontSize: 18, color: Colors.blue)),
                    Text("Pending Balance: ₹$balanceAmount",
                        style: TextStyle(fontSize: 18, color: Colors.red)),
                    SizedBox(height: 20),

                    // Input Box for Payment Amount
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Enter paid Amount",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Date Picker Input Box
                    TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Select Payment Date",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context),
                    ),
                    SizedBox(height: 20),

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
                            onPressed: _isLoading ? null : payFees,
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
                                        'Pay',
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
        ));
  }
}
