// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentHistoryPage extends StatefulWidget {
  final String feeId;

  const PaymentHistoryPage({super.key, required this.feeId});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          'Payment History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection("fees").doc(widget.feeId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            double balanceAmount = (data["balanceAmount"] ?? 0).toDouble();
            double totalAmount = (data["totalAmount"] ?? 0).toDouble();
            List payments = List.from(data["paymentHistory"] ?? []);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "Total Fees: ₹$totalAmount",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                payments.isEmpty
                    ? const Center(child: Text("No payment history found."))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: payments.length,
                          itemBuilder: (context, index) {
                            var payment = payments[index];
                            bool isLastItem = index == payments.length - 1;

                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.payments,
                                    color: Colors.green),
                                title: Text(
                                    "Paid Amount: ₹${payment["paidAmount"]}"),
                                subtitle: Text(
                                  "Balance: ₹${payment["balanceAmount"]}\nDate: ${payment["paymentDate"]}",
                                ),
                                trailing: isLastItem
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () {
                                              _editPayment(context, index,
                                                  payment, balanceAmount);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {
                                              _deletePayment(index);
                                            },
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _editPayment(BuildContext context, int index,
      Map<String, dynamic> payment, double balanceAmount) {
    TextEditingController amountController =
        TextEditingController(text: payment["paidAmount"].toString());
    TextEditingController dateController =
        TextEditingController(text: payment["paymentDate"]);
    TextEditingController balanceController =
        TextEditingController(text: payment["balanceAmount"].toString());

    double initialPaidAmount = double.tryParse(amountController.text) ?? 0;
    double initialBalanceAmount = payment["balanceAmount"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Payment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Paid Amount"),
                onChanged: (value) {
                  double newPaidAmount =
                      double.tryParse(value) ?? initialPaidAmount;

                  double updatedBalanceAmount = initialBalanceAmount +
                      (initialPaidAmount - newPaidAmount);
                  balanceController.text = updatedBalanceAmount.toString();
                },
              ),
              TextField(
                controller: balanceController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Balance Amount"),
              ),
              TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: "Payment Date"),
                  readOnly: true,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      dateController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    }
                  }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });

                      double newPaidAmount =
                          double.tryParse(amountController.text) ??
                              initialPaidAmount;
                      double updatedBalanceAmount = initialBalanceAmount +
                          (initialPaidAmount - newPaidAmount);

                      if (newPaidAmount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invalid amount!")),
                        );
                        return;
                      }

                      try {
                        DocumentReference docRef =
                            _firestore.collection("fees").doc(widget.feeId);
                        var doc = await docRef.get();
                        var data = doc.data() as Map<String, dynamic>;
                        List paymentHistory = List.from(data["paymentHistory"]);

                        paymentHistory[index] = {
                          "paidAmount": newPaidAmount,
                          "balanceAmount": updatedBalanceAmount,
                          "paymentDate": dateController.text,
                        };

                        double updatedPaidAmount = (data["paidAmount"] ?? 0) -
                            initialPaidAmount +
                            newPaidAmount;

                        await docRef.update({
                          "paymentHistory": paymentHistory,
                          "paidAmount":
                              updatedPaidAmount, // नवीन Paid Amount अपडेट केला आहे

                          "balanceAmount": updatedBalanceAmount,
                        });

                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: ${e.toString()}")),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Color.fromARGB(255, 255, 255, 255))
                  : const Text("Update"),
            )
          ],
        );
      },
    );
  }

  void _deletePayment(int index) async {
    try {
      DocumentReference docRef =
          _firestore.collection("fees").doc(widget.feeId);
      var doc = await docRef.get();
      var data = doc.data() as Map<String, dynamic>? ?? {};
      List paymentHistory = List.from(data["paymentHistory"] ?? []);

      if (index >= paymentHistory.length) return;

      double deletedAmount = paymentHistory[index]["paidAmount"];

      paymentHistory.removeAt(index);

      double newBalanceAmount = (data["balanceAmount"] ?? 0) + deletedAmount;

      await docRef.update({
        "paymentHistory": paymentHistory,
        "paidAmountSum": (data["paidAmountSum"] ?? 0) - deletedAmount,
        "balanceAmount": newBalanceAmount,
      });
    } catch (e) {
      print("Error: $e");
    }
  }
}
