  // ignore_for_file: prefer_final_fields, avoid_print, use_build_context_synchronously, deprecated_member_use, unused_field, unused_local_variable, no_leading_underscores_for_local_identifiers

  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';

  class AdminAddTestPage extends StatefulWidget {
    const AdminAddTestPage({super.key});

    @override
    _AdminAddTestPageState createState() => _AdminAddTestPageState();
  }

  class _AdminAddTestPageState extends State<AdminAddTestPage> {
    final _isLoading = false;

    final TextEditingController _testNameController = TextEditingController();
    final TextEditingController _totalMarksController = TextEditingController();
    final TextEditingController _isDurationMinutesController =
        TextEditingController();
    final TextEditingController _testDateController =
        TextEditingController(); // Test Date
    final TextEditingController _testTimeController =
        TextEditingController(); // Test Time

    String? _selectedClass;
    List<String> classList = [];
    final CollectionReference testsCollection =
        FirebaseFirestore.instance.collection('tests');
    final CollectionReference classCollection =
        FirebaseFirestore.instance.collection('class');

    bool _isTestNameValid = true;
    bool _isTotalMarksValid = true;
    bool _isDurationMinutes = true;
    bool _isClassSelected = true;
    bool _isTestDateValid = true;
    bool _isTestTimeValid = true;

    @override
    void initState() {
      super.initState();
      fetchClass();
    }

    @override
    void dispose() {
      _testNameController.dispose();
      _totalMarksController.dispose();
      _isDurationMinutesController.dispose();
      _testDateController.dispose();
      _testTimeController.dispose();
      super.dispose();
    }

    void fetchClass() async {
      try {
        QuerySnapshot snapshot = await classCollection.get();
        setState(() {
          classList = snapshot.docs.map((doc) => doc['name'] as String).toList();
          _selectedClass = null;
        });
      } catch (e) {
        print("Error fetching class: $e");
      }
    }

    Future<void> _selectDate() async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (pickedDate != null) {
        setState(() {
          _testDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
          _isTestDateValid = true;
        });
      }
    }

    Future<void> _selectTime() async {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _testTimeController.text = pickedTime.format(context);
          _isTestTimeValid = true;
        });
      }
    }

    void addTest() {
      setState(() {
        _isTestNameValid = _testNameController.text.isNotEmpty;
        _isTotalMarksValid = _totalMarksController.text.isNotEmpty;
        _isDurationMinutes = _isDurationMinutesController.text.isNotEmpty;
        _isClassSelected = _selectedClass != null;
        _isTestDateValid = _testDateController.text.isNotEmpty;
        _isTestTimeValid = _testTimeController.text.isNotEmpty;
      });

      if (_isTestNameValid &&
          _isTotalMarksValid &&
          _isDurationMinutes &&
          _isClassSelected &&
          _isTestDateValid &&
          _isTestTimeValid) {
        int totalMarks = int.tryParse(_totalMarksController.text) ?? 0;
        int durationMinutes =
            int.tryParse(_isDurationMinutesController.text) ?? 0;

        testsCollection.add({
          'name': _testNameController.text,
          'class': _selectedClass,
          'totalMarks': totalMarks,
          'durationMinutes': durationMinutes,
          'testDate': _testDateController.text,
          'testTime': _testTimeController.text,
        }).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Test added successfully!')));
          Navigator.pop(context);
        }).catchError((error) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error adding test: $error')));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all fields')));
      }
    }

    @override
    Widget build(BuildContext context) {
      double screenWidth = MediaQuery.of(context).size.width;

      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Add Test',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
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
                  mainAxisSize: MainAxisSize.min, // Content la compact thevte
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Content center madhe
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Horizontally center
                  children: [
                    _buildTextField(
                        label: 'Test Name',
                        controller: _testNameController,
                        isValid: _isTestNameValid,
                        errorText: 'Please enter the test name'),
                    const SizedBox(height: 10),
                    _buildTextField(
                        label: 'Total Marks',
                        controller: _totalMarksController,
                        isValid: _isTotalMarksValid,
                        errorText: 'Please enter the total marks',
                        inputType: TextInputType.number),
                    const SizedBox(height: 10),
                    _buildTextField(
                        label: 'Duration (Minutes)',
                        controller: _isDurationMinutesController,
                        isValid: _isDurationMinutes,
                        errorText: 'Please enter the duration',
                        inputType: TextInputType.number),
                    const SizedBox(height: 10),
                    _buildTextField(
                        label: 'Test Date',
                        controller: _testDateController,
                        isValid: _isTestDateValid,
                        errorText: 'Please select a test date',
                        onTap: _selectDate,
                        readOnly: true),
                    const SizedBox(height: 10),
                    _buildTextField(
                        label: 'Test Time',
                        controller: _testTimeController,
                        isValid: _isTestTimeValid,
                        errorText: 'Please select a test time',
                        onTap: _selectTime,
                        readOnly: true),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      onChanged: (String? newValue) => setState(() {
                        _selectedClass = newValue;
                        _isClassSelected = true;
                      }),
                      isExpanded: true,
                      items: classList
                          .map((String className) => DropdownMenuItem<String>(
                              value: className, child: Text(className)))
                          .toList(),
                      decoration: InputDecoration(
                          hintText: 'Class',
                          errorText:
                              _isClassSelected ? null : 'Please select the class',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0))),
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
                            onPressed: _isLoading ? null : addTest,
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
                                        'Add Test',
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

    Widget _buildTextField(
        {required String label,
        required TextEditingController controller,
        required bool isValid,
        required String errorText,
        TextInputType inputType = TextInputType.text,
        VoidCallback? onTap,
        bool readOnly = false}) {
      return TextField(
        controller: controller,
        keyboardType: inputType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
            hintText: label,
            errorText: isValid ? null : errorText,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
      );
    }
  }
