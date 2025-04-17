import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shri_ganesh_classes/pages/admin_edit_fess_page.dart';
import 'package:shri_ganesh_classes/pages/admin_pay_pending_fees_page.dart';
import 'package:shri_ganesh_classes/pages/admin_payment_history_page.dart';
import 'package:shri_ganesh_classes/pages/app_drawer.dart';

class AdminListFeesPage extends StatefulWidget {
  const AdminListFeesPage({super.key});

  @override
  _AdminListFeesPageState createState() => _AdminListFeesPageState();
}

class _AdminListFeesPageState extends State<AdminListFeesPage> {
  final Stream<QuerySnapshot> feesStream =
      FirebaseFirestore.instance.collection('fees').snapshots();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = "";
  String? selectedClass;
  List<String> classList = ["Selecte Class"];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    var classSnapshot = await _firestore.collection('class').get();
    setState(() {
      classList.addAll(
          classSnapshot.docs.map((doc) => doc['name'] as String).toList());
      selectedClass = "Selecte Class";
    });
  }

  void deleteFeeRecord(String id) {
    FirebaseFirestore.instance.collection('fees').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fee record deleted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: feesStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List storedocs =
            snapshot.data!.docs.map((DocumentSnapshot document) {
          Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
          data['id'] = document.id;
          return data;
        }).toList();

        final List filteredDocs = storedocs.where((doc) {
          bool matchesSearch = searchQuery.isEmpty ||
              doc['studentName'].toLowerCase().contains(searchQuery) ||
              doc['feesType'].toLowerCase().contains(searchQuery);

          bool matchesClass =
              selectedClass == "Selecte Class" || doc['class'] == selectedClass;

          return matchesSearch && matchesClass;
        }).toList();

        return Scaffold(
          // ignore: avoid_types_as_parameter_names
          drawer: AppDrawer(onSelectPage: (widget) {}),
          body: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Box & Dropdown - Row Layout
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Search Field
                        Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.purple
                              ], // Gradient border
                            ),
                          ),
                          padding:
                              EdgeInsets.all(2), // Creates the border effect
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by Name, Fee Type',
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

                        // Dropdown Field
                        Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.purple
                              ], // Gradient border
                            ),
                          ),
                          padding:
                              EdgeInsets.all(2), // Creates the border effect
                          child: DropdownButtonFormField<String>(
                            value: selectedClass,
                            items: classList.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child:
                                    Text(value, style: TextStyle(fontSize: 16)),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedClass = newValue!;
                              });
                            },
                            isExpanded: true,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black),
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
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
                  ),

                  // Table Container
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 20.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 800,
                          maxWidth: 1200,
                        ),
                        child: Table(
                          border: TableBorder.all(),
                          columnWidths: const <int, TableColumnWidth>{
                            1: FixedColumnWidth(140),
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(
                              children: [
                                tableHeader('Fees Type'),
                                tableHeader('Student Name'),
                                tableHeader('Class'),
                                tableHeader('Total Amount'),
                                tableHeader('Paid Amount'),
                                tableHeader('Balance Amount'),
                                tableHeader('Payment Date'),
                                tableHeader('Action'),
                              ],
                            ),
                            for (var i = 0; i < filteredDocs.length; i++)
                              TableRow(
                                children: [
                                  tableCell(filteredDocs[i]['feesType'] ??
                                      'No Fees Type'),
                                  tableCell(filteredDocs[i]['studentName'] ??
                                      'No Student Name'),
                                  tableCell(filteredDocs[i]['class'] ?? '-'),
                                  tableCell(filteredDocs[i]['totalAmount']
                                      .toString()),
                                  tableCell(
                                      filteredDocs[i]['paidAmount'].toString()),
                                  tableCell(filteredDocs[i]['balanceAmount']
                                      .toString()),
                                  tableCell(
                                      filteredDocs[i]['paymentDate'] ?? '-'),
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Tooltip(
                                                message: 'Pay Fees',
                                                child: IconButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AdminPayPendingFeesPage(
                                                          feeId: filteredDocs[i]
                                                              ['id'],
                                                          totalAmount:
                                                              filteredDocs[i][
                                                                  'totalAmount'],
                                                          paidAmount:
                                                              filteredDocs[i][
                                                                  'paidAmount'],
                                                          balanceAmount:
                                                              filteredDocs[i][
                                                                  'balanceAmount'],
                                                          paymentDate:
                                                              filteredDocs[i][
                                                                  'paymentDate'],
                                                          studentName:
                                                              filteredDocs[i][
                                                                  'studentName'],
                                                          className:
                                                              filteredDocs[i]
                                                                  ['class'],
                                                          feesType:
                                                              filteredDocs[i]
                                                                  ['feesType'],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                      Icons.payment,
                                                      color: Color.fromARGB(
                                                          255, 50, 21, 215)),
                                                ),
                                              ),
                                              Tooltip(
                                                message: 'View Payment History',
                                                child: IconButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            PaymentHistoryPage(
                                                          feeId: filteredDocs[i]
                                                              ['id'],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                      Icons.payments,
                                                      color: Colors.green),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Tooltip(
                                                message: 'Edit Fees',
                                                child: IconButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AdminEditFeesPage(
                                                          feeId: filteredDocs[i]
                                                              ['id'],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blue),
                                                ),
                                              ),
                                              Tooltip(
                                                message: 'Delete Fees',
                                                child: IconButton(
                                                  onPressed: () {
                                                    deleteFeeRecord(
                                                        filteredDocs[i]['id']);
                                                  },
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TableCell tableHeader(String text) {
    return TableCell(
      child: Container(
        color: const Color.fromARGB(255, 244, 247, 244),
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Color.fromARGB(255, 13, 13, 13),
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
        ),
      ),
    );
  }

  TableCell tableCell(String text) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18.0),
          ),
        ),
      ),
    );
  }
}
