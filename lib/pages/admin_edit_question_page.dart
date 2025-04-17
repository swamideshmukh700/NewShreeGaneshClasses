// ignore_for_file: use_super_parameters, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditQuestionPage extends StatefulWidget {
  final String questionId;
  final Map<String, dynamic> questionData;

  const EditQuestionPage({
    Key? key,
    required this.questionId,
    required this.questionData,
  }) : super(key: key);

  @override
  _EditQuestionPageState createState() => _EditQuestionPageState();
}

class _EditQuestionPageState extends State<EditQuestionPage> {
  bool _isLoading = false;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();
  final TextEditingController _correctAnswerController =
      TextEditingController();
  final TextEditingController _marksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.questionData['question'];
    _optionAController.text = widget.questionData['optionA'];
    _optionBController.text = widget.questionData['optionB'];
    _optionCController.text = widget.questionData['optionC'];
    _optionDController.text = widget.questionData['optionD'];
    _correctAnswerController.text = widget.questionData['correctAnswer'];
    _marksController.text = widget.questionData['marks'].toString();
  }

  void updateQuestion() async {
    setState(() {
      _isLoading = true;
    });
    await FirebaseFirestore.instance
        .collection('questions')
        .doc(widget.questionId)
        .update({
      'question': _questionController.text,
      'optionA': _optionAController.text,
      'optionB': _optionBController.text,
      'optionC': _optionCController.text,
      'optionD': _optionDController.text,
      'correctAnswer': _correctAnswerController.text,
      'marks': int.parse(_marksController.text),
    });

    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question updated successfully!')),
    );
    Navigator.pop(context);
  }

  Widget buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title:
            const Text('Edit Question', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Fix for Bottom Overflow
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width:
                MediaQuery.of(context).size.width > 500 ? 500 : double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildInputField("Question", _questionController),
                buildInputField("Option A", _optionAController),
                buildInputField("Option B", _optionBController),
                buildInputField("Option C", _optionCController),
                buildInputField("Option D", _optionDController),
                buildInputField("Correct Answer", _correctAnswerController),
                buildInputField("Marks", _marksController),
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
                        onPressed: _isLoading ? null : updateQuestion,
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
