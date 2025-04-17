// ignore_for_file: avoid_print, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shri_ganesh_classes/pages/user_test_list_page.dart';

class TestReviewPage extends StatefulWidget {
  final String testId;
  final String studentEmail;

  const TestReviewPage({
    super.key,
    required this.testId,
    required this.studentEmail,
  });

  @override
  _TestReviewPageState createState() => _TestReviewPageState();
}

class _TestReviewPageState extends State<TestReviewPage> {
  List<Map<String, dynamic>> questions = [];
  Map<String, String?> studentAnswers = {};
  bool isLoading = true;
  int obtainedMarks = 0;
  int totalMarks = 0;
  String studentId = '';
  String studentClass = '';

  @override
  void initState() {
    super.initState();
    fetchTestResults();
  }

  Future<void> fetchTestResults() async {
    try {
      QuerySnapshot questionDocs = await FirebaseFirestore.instance
          .collection('questions')
          .where('testId', isEqualTo: widget.testId)
          .get();

      List<Map<String, dynamic>> fetchedQuestions = questionDocs.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      QuerySnapshot attemptDocs = await FirebaseFirestore.instance
          .collection('test_attempts')
          .where('testId', isEqualTo: widget.testId)
          .where('email', isEqualTo: widget.studentEmail)
          .get();

      if (attemptDocs.docs.isNotEmpty) {
        var attemptData = attemptDocs.docs.first.data() as Map<String, dynamic>;

        obtainedMarks = int.tryParse(attemptData["yourScore"].toString()) ?? 0;
        totalMarks = int.tryParse(attemptData["totalMarks"].toString()) ?? 0;

        studentId = attemptData["studentId"] ?? "";
        studentClass = attemptData["studentClass"] ?? "";

        List<dynamic> storedAnswers = attemptData["selectedAnswers"] ?? [];
        for (int i = 0; i < storedAnswers.length; i++) {
          String key = fetchedQuestions[i]['testId'].toString();
          studentAnswers[key] = storedAnswers[i] as String?;
        }
      }

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching test results: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Test Review',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : questions.isEmpty
              ? const Center(child: Text("No data available"))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        "Total Score: $obtainedMarks / $totalMarks",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            final question = questions[index];

                            final String questionId =
                                question['testId'].toString();
                            final userAnswer =
                                studentAnswers[questionId] ?? "Not Answered";
                            final correctAnswer = question['correctAnswer'];

                            Map<String, String> options = {
                              'A': question['optionA'] ?? '',
                              'B': question['optionB'] ?? '',
                              'C': question['optionC'] ?? '',
                              'D': question['optionD'] ?? '',
                            };

                            bool isCorrect = userAnswer == correctAnswer;

                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// **प्रश्न आणि मार्क्स उजव्या वरच्या बाजूला**
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "${index + 1}. ${question['question']}",
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "Marks: ${question['marks']}",
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    /// **Your answer is correct / incorrect message**
                                    Text(
                                      isCorrect
                                          ? "✅ Your answer is correct"
                                          : "❌ Your answer is incorrect",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isCorrect
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    /// **चारही पर्याय दाखवणे**
                                    ...options.entries.map((entry) {
                                      bool isUserAnswer =
                                          userAnswer == entry.key;
                                      bool isCorrectAnswer =
                                          correctAnswer == entry.key;

                                      return ListTile(
                                        title: Text(
                                          "${entry.key}: ${entry.value}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isCorrectAnswer
                                                ? Colors.green
                                                : (isUserAnswer
                                                    ? Colors.red
                                                    : Colors.black),
                                            fontWeight:
                                                isCorrectAnswer || isUserAnswer
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                        trailing: isUserAnswer
                                            ? (isCorrectAnswer
                                                ? const Icon(Icons.check_circle,
                                                    color: Colors.green)
                                                : const Icon(Icons.cancel,
                                                    color: Colors.red))
                                            : null,
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: SizedBox(
                            width: 180, // Button Width
                            height: 55, // Button Height
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                foregroundColor: Colors.white,
                              ).copyWith(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith(
                                  (states) => Colors.transparent,
                                ),
                                shadowColor:
                                    WidgetStateProperty.all(Colors.transparent),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => UserTestListPage(
                                            studentEmail: widget.studentEmail,
                                            studentId: studentId,
                                            studentClass: studentClass,
                                            tests:
                                                '', // ✅ इसे एक खाली लिस्ट पास करें
                                            testId: '', fullName: '',
                                          )), // Navigate to UserTestListPage
                                );
                              },
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
                                  child: const Text(
                                    "Back to Home",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
