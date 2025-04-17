// ignore_for_file: use_build_context_synchronously, deprecated_member_use, prefer_final_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminEditTestPage extends StatefulWidget {
  final String testId;
  final String testName;
  final String testClass;
  final num totalMarks;
  final num durationMinutes;
  final String testDate;
  final String testTime;

  const AdminEditTestPage({
    super.key,
    required this.testId,
    required this.testName,
    required this.testClass,
    required this.totalMarks,
    required this.durationMinutes,
    required this.testDate,
    required this.testTime,
  });

  @override
  _AdminEditTestPageState createState() => _AdminEditTestPageState();
}

class _AdminEditTestPageState extends State<AdminEditTestPage> {
  Color appBarTitleColor = Colors.white;
  Color backArrowColor = Colors.white;
  Color addIconColor = Colors.white;
  late TextEditingController nameController;
  late TextEditingController marksController;
  late TextEditingController durationMinutesController;
  late TextEditingController dateController;
  late TextEditingController timeController;

  String? selectedClass;
  List<String> classList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.testName);
    marksController = TextEditingController(text: widget.totalMarks.toString());
    durationMinutesController =
        TextEditingController(text: widget.durationMinutes.toString());
    dateController = TextEditingController(text: widget.testDate);
    timeController = TextEditingController(text: widget.testTime);
    selectedClass = widget.testClass.isNotEmpty ? widget.testClass : null;

    _fetchClass();
  }

  Future<void> _fetchClass() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('class').get();
      List<String> fetchedClass =
          snapshot.docs.map((doc) => doc['name'].toString()).toList();

      setState(() {
        classList = fetchedClass;
        if (!classList.contains(selectedClass)) {
          selectedClass = classList.isNotEmpty ? classList.first : null;
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching class: $error')),
      );
    }
  }

  Future<void> _updateTest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('tests')
          .doc(widget.testId)
          .update({
        'name': nameController.text.trim(),
        'class': selectedClass ?? widget.testClass,
        'totalMarks': num.tryParse(marksController.text) ?? 0,
        'durationMinutes': num.tryParse(durationMinutesController.text) ?? 0,
        'testDate': dateController.text.trim(),
        'testTime': timeController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test updated successfully!')),
      );
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Update Test',
          style: TextStyle(
            color: appBarTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: backArrowColor),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Container(
              width: screenWidth < 400 ? screenWidth * 0.85 : 350,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameController, 'Test Name'),
                  const SizedBox(height: 10),
                  _buildDropdown(),
                  const SizedBox(height: 10),
                  _buildTextField(marksController, 'Total Marks',
                      isNumeric: true),
                  const SizedBox(height: 10),
                  _buildTextField(
                      durationMinutesController, 'Set Time (Minutes)',
                      isNumeric: true),
                  const SizedBox(height: 10),
                  _buildDateField(),
                  const SizedBox(height: 10),
                  _buildTimeField(),
                  const SizedBox(height: 20),
                  _buildUpdateButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedClass,
      items: classList
          .map((className) =>
              DropdownMenuItem(value: className, child: Text(className)))
          .toList(),
      decoration: InputDecoration(
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
      onChanged: (value) => setState(() => selectedClass = value),
    );
  }

  Widget _buildDateField() {
    return TextField(
      controller: dateController,
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Test Date',
        suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today), onPressed: _selectDate),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  Widget _buildTimeField() {
    return TextField(
      controller: timeController,
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Test Time',
        suffixIcon: IconButton(
            icon: const Icon(Icons.access_time), onPressed: _selectTime),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Padding(
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
              shadowColor: WidgetStateProperty.all(Colors.transparent),
            ),
            onPressed: _isLoading ? null : _updateTest,
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
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
