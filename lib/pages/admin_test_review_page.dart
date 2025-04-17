import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminTestReviewPage extends StatefulWidget {
  final String testId;

  const AdminTestReviewPage({super.key, required this.testId});

  @override
  State<AdminTestReviewPage> createState() => _AdminTestReviewPageState();
}

class _AdminTestReviewPageState extends State<AdminTestReviewPage> {
  List<Map<String, dynamic>> attempts = [];
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttemptsAndQuestions();
  }

  Future<void> fetchAttemptsAndQuestions() async {
    try {
      // Fetch attempts
      QuerySnapshot attemptSnapshot = await FirebaseFirestore.instance
          .collection('test_attempts')
          .where('testId', isEqualTo: widget.testId)
          .get();

      attempts = attemptSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Fetch questions
      QuerySnapshot questionSnapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('testId', isEqualTo: widget.testId)
          .get();

      questions = questionSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String getQuestionText(int index) {
    if (index >= 0 && index < questions.length) {
      return questions[index]['question'] ?? '';
    }
    return '';
  }

  String getCorrectAnswer(int index) {
    if (index >= 0 && index < questions.length) {
      return questions[index]['correctAnswer'] ?? '';
    }
    return '';
  }

  String getOptionText(int index, String option) {
    if (index >= 0 && index < questions.length) {
      return questions[index]['option$option'] ?? '';
    }
    return '';
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Test Review',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: attempts.length,
              itemBuilder: (context, attemptIndex) {
                final attempt = attempts[attemptIndex];
                final List selectedAnswers =
                    attempt['selectedAnswers'] ?? List.empty();

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ExpansionTile(
                    title: Text(
                        "Student Name: ${attempt['fullName']}\nMarks ${attempt['yourScore']}/ Total Marks${attempt['totalMarks']}"),
                    children: List.generate(
                      questions.length,
                      (index) {
                        String correct = getCorrectAnswer(index);
                        String selected = selectedAnswers.length > index
                            ? selectedAnswers[index] ?? ''
                            : '';
                        bool isCorrect = selected == correct;

                        return ListTile(
                          title:
                              Text("${index + 1}. ${getQuestionText(index)}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Student Answer : $selected - ${getOptionText(index, selected)}",
                                  style: TextStyle(
                                      color: isCorrect
                                          ? Colors.green
                                          : Colors.red)),
                              Text(
                                  "Correct Answer: $correct - ${getOptionText(index, correct)}",
                                  style: const TextStyle(color: Colors.blue)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
