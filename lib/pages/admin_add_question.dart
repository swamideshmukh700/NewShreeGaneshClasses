// ignore_for_file: use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shri_ganesh_classes/pages/admin_list_question.dart';

class QuestionAddPage extends StatefulWidget {
  final String testId;
  const QuestionAddPage({Key? key, required this.testId}) : super(key: key);

  @override
  _QuestionAddPageState createState() => _QuestionAddPageState();
}

class _QuestionAddPageState extends State<QuestionAddPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();
  final TextEditingController _correctAnswerController =
      TextEditingController();
  final TextEditingController _marksController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitted = false;
  int testTotalMarks = 0; // **Firestore मधून मिळेल**
  int remainingMarks = 0;
  Color appBarTitleColor = Colors.white;
  Color backArrowColor = Colors.white;
  List<Map<String, dynamic>> tempQuestions = [];

  @override
  void initState() {
    super.initState();
    fetchTotalMarks();
    checkIfQuestionsExist();
  }

  Future<void> checkIfQuestionsExist() async {
    try {
      QuerySnapshot questionSnapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('testId', isEqualTo: widget.testId)
          .get();

      if (questionSnapshot.docs.isNotEmpty) {
        // जर आधीच प्रश्न असतील, तर नवीन प्रश्न अॅड करता येऊ नयेत
        setState(() {
          _isSubmitted = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test already added!'),
            backgroundColor: Color.fromARGB(255, 16, 16, 16),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking questions: $e')),
      );
    }
  }

  // **🔥 Firestore मधून Total Marks आणणे**
  Future<void> fetchTotalMarks() async {
    try {
      DocumentSnapshot testDoc = await FirebaseFirestore.instance
          .collection('tests')
          .doc(widget.testId)
          .get();

      if (testDoc.exists) {
        int fetchedMarks = testDoc['totalMarks'] ?? 0;
        setState(() {
          testTotalMarks = fetchedMarks;
          remainingMarks = fetchedMarks;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching total marks: $e')),
      );
    }
  }

  // **🔥 नवीन प्रश्न अॅड करणे**
  void addQuestion() {
    String marksText = _marksController.text;

    // **🔥 Check if Marks is a valid number**
    if (marksText.isEmpty || int.tryParse(marksText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks must be a valid number!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int newQuestionMarks = int.parse(marksText);

    // **🔥 Check if marks is negative or greater than remaining marks**
    if (newQuestionMarks <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks must be a positive number!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newQuestionMarks > remainingMarks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can only add up to $remainingMarks marks!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String correctAnswer = _correctAnswerController.text.toUpperCase();

    if (_questionController.text.isNotEmpty &&
        _optionAController.text.isNotEmpty &&
        _optionBController.text.isNotEmpty &&
        _optionCController.text.isNotEmpty &&
        _optionDController.text.isNotEmpty &&
        _correctAnswerController.text.isNotEmpty) {
      if (!['A', 'B', 'C', 'D'].contains(correctAnswer)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correct Answer must be A, B, C, or D!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic> questionData = {
        'question': _questionController.text,
        'optionA': _optionAController.text,
        'optionB': _optionBController.text,
        'optionC': _optionCController.text,
        'optionD': _optionDController.text,
        'correctAnswer': correctAnswer,
        'marks': newQuestionMarks,
      };

      setState(() {
        tempQuestions.add(questionData);
        remainingMarks -= newQuestionMarks;
      });

      resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields must be filled!')),
      );
    }
  }

  // **🔥 सर्व प्रश्न Firebase मध्ये सबमिट करणे**
  Future<void> submitAllQuestions() async {
    setState(() {
      _isLoading = true;
    });

    for (var question in tempQuestions) {
      await FirebaseFirestore.instance.collection('questions').add({
        ...question,
        'testId': widget.testId,
      });
    }

    tempQuestions.clear();

    await FirebaseFirestore.instance.collection('submitted_tests').add({
      'testId': widget.testId,
      'submittedAt': Timestamp.now(),
    });

    setState(() {
      _isSubmitted = true;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All questions submitted successfully!')));

    Navigator.pop(context);
  }

  // **🔥 फॉर्म रीसेट करणे**
  void resetForm() {
    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    _correctAnswerController.clear();
    _marksController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple], // Gradient colors
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: MouseRegion(
              onEnter: (_) {
                setState(() {
                  appBarTitleColor = Colors.orange;
                });
              },
              onExit: (_) {
                setState(() {
                  appBarTitleColor = Colors.white;
                });
              },
              child: Text(
                'Add Question',
                style: TextStyle(
                  color: appBarTitleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent, // Make AppBar transparent
            elevation: 0, // Remove shadow
            iconTheme: IconThemeData(color: backArrowColor),
            leading: MouseRegion(
              onEnter: (_) {
                setState(() {
                  backArrowColor = Colors.orange;
                });
              },
              onExit: (_) {
                setState(() {
                  backArrowColor = Colors.white;
                });
              },
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  testTotalMarks == 0
                      ? const CircularProgressIndicator() // 🔄 Loading Indicator
                      : _isSubmitted
                          ? AlertDialog(
                              title: const Text(
                                'Already Added !',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                'All questions have been already added!',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminQuestionListPage(
                                            testId: widget.testId),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text('Remaining Marks: $remainingMarks',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red)),
                                  const SizedBox(height: 10),

                                  // 🔹 प्रश्न ListView मध्ये
                                  SizedBox(
                                    height: 300, // ListView साठी मर्यादित उंची
                                    child: ListView.builder(
                                      itemCount: tempQuestions.length,
                                      itemBuilder: (context, index) {
                                        var question = tempQuestions[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  "Q${index + 1}: ${question['question']}",
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(
                                                  "🔹 Marks: ${question['marks']}",
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.red)),
                                              Text("A) ${question['optionA']}",
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                              Text("B) ${question['optionB']}",
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                              Text("C) ${question['optionC']}",
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                              Text("D) ${question['optionD']}",
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                              Text(
                                                  "✅ Correct Answer: ${question['correctAnswer']}",
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // 🔹 Add Question Form (जर remainingMarks > 0 असेल तरच)
                                  if (remainingMarks > 0) ...[
                                    TextField(
                                        controller: _questionController,
                                        decoration: const InputDecoration(
                                            labelText: 'Question')),
                                    TextField(
                                        controller: _optionAController,
                                        decoration: const InputDecoration(
                                            labelText: 'Option A')),
                                    TextField(
                                        controller: _optionBController,
                                        decoration: const InputDecoration(
                                            labelText: 'Option B')),
                                    TextField(
                                        controller: _optionCController,
                                        decoration: const InputDecoration(
                                            labelText: 'Option C')),
                                    TextField(
                                        controller: _optionDController,
                                        decoration: const InputDecoration(
                                            labelText: 'Option D')),
                                    TextField(
                                        controller: _correctAnswerController,
                                        decoration: const InputDecoration(
                                            labelText: 'Correct Answer')),
                                    TextField(
                                        controller: _marksController,
                                        decoration: const InputDecoration(
                                            labelText: 'Marks')),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : addQuestion,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.all(12),
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blue,
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white)
                                          : const Text('Add Question',
                                              style: TextStyle(fontSize: 18)),
                                    ),
                                  ],

                                  // 🔹 Submit बटण (जर remainingMarks == 0 असेल तर)
                                  if (remainingMarks == 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : submitAllQuestions,
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          padding: const EdgeInsets.all(12),
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.green,
                                        ),
                                        child: _isLoading
                                            ? const CircularProgressIndicator(
                                                color: Colors.white)
                                            : const Text('Submit',
                                                style: TextStyle(fontSize: 18)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
