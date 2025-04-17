// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, unnecessary_brace_in_string_interps, avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shri_ganesh_classes/pages/user_test_review_page.dart';

class UserTestQuestionsPage extends StatefulWidget {
  final String testId;
  final String studentEmail;
  final String fullName;

  const UserTestQuestionsPage(
      {super.key,
      required this.testId,
      required this.studentEmail,
      required this.fullName,
      required String studentId});

  @override
  _UserTestQuestionsPageState createState() => _UserTestQuestionsPageState();
}

class _UserTestQuestionsPageState extends State<UserTestQuestionsPage> {
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;
  Map<int, String?> selectedAnswers = {};
  int remainingTimeInSeconds = 0;
  Timer? _timer;
  bool showSubmitButton = false;
  int currentIndex = 0;
  late String name = "";
  late int totalMarks = 0;
  int obtainedMarks = 0;
  bool isTestCompleted = false;

  Color nameColor = Colors.white;
  Color marksColor = Colors.white;
  Color backArrowColor = Colors.white;

  @override
  void initState() {
    super.initState();
    fetchTestDetails();
  }

  Future<void> fetchTestDetails() async {
    try {
      DocumentSnapshot testDoc = await FirebaseFirestore.instance
          .collection('tests')
          .doc(widget.testId)
          .get();
      if (testDoc.exists) {
        int durationInMinutes = testDoc['durationMinutes'] ?? 2;
        remainingTimeInSeconds = durationInMinutes * 60;
        name = testDoc['name'] ?? 'Test';
        totalMarks = testDoc['totalMarks'] ?? 0;
        setState(() {});
        await fetchQuestions();
        startTimer();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchQuestions() async {
    try {
      QuerySnapshot questionDocs = await FirebaseFirestore.instance
          .collection('questions')
          .where('testId', isEqualTo: widget.testId)
          .get();

      List<Map<String, dynamic>> fetchedQuestions = questionDocs.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Print test IDs that match
      for (var doc in questionDocs.docs) {
        print("Matching Test ID: ${doc['testId']}");
      }

     

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching questions: $e");
      setState(() => isLoading = false);
    }
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeInSeconds > 0) {
        setState(() {
          remainingTimeInSeconds--;
          showSubmitButton = remainingTimeInSeconds <= 60;
        });
      } else {
        timer.cancel();
        autoSubmitTest();
      }
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  void autoSubmitTest() {
    if (!isTestCompleted) {
      calculateScore();
      saveTestAttempt();
      showScoreDialog();
    }
  }

  void calculateScore() {
    obtainedMarks = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]['correctAnswer']) {
        obtainedMarks += (questions[i]['marks'] ?? 0) as int;
      }
    }
  }

  void saveTestAttempt() async {
    try {
      
      await FirebaseFirestore.instance.collection('test_attempts').add({
        "testId": widget.testId,
        "testName": name,
        "email": widget.studentEmail,
        'fullName': widget.fullName,
        "yourScore": obtainedMarks.toString(),
        "totalMarks": totalMarks.toString(),
        "attemptedAt": FieldValue.serverTimestamp(),
        "selectedAnswers": selectedAnswers.values.toList(),
      });
      setState(() => isTestCompleted = true);
      // ignore: empty_catches
    } catch (e) {}
  }

  void showScoreDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Test Completed"),
          content: Text("You scored $obtainedMarks out of $totalMarks"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestReviewPage(
                      testId: widget.testId,
                      studentEmail: widget.studentEmail,
                    ),
                  ),
                );
              },
              child: const Text("View Answers"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => nameColor = Colors.orange),
              onExit: (_) => setState(() => nameColor = Colors.white),
              child: Text(name,
                  style: TextStyle(fontSize: 16, color: nameColor),
                  textAlign: TextAlign.center),
            ),
            MouseRegion(
              onEnter: (_) => setState(() => marksColor = Colors.orange),
              onExit: (_) => setState(() => marksColor = Colors.white),
              child: Text("Total Marks: $totalMarks",
                  style: TextStyle(fontSize: 12, color: marksColor),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
        centerTitle: true,
        leading: MouseRegion(
          onEnter: (_) => setState(() => backArrowColor = Colors.orange),
          onExit: (_) => setState(() => backArrowColor = Colors.white),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: backArrowColor),
            onPressed: () {},
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              "Time Left: ${formatTime(remainingTimeInSeconds)}",
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : questions.isEmpty
              ? const Center(child: Text("No questions available"))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (questions
                                    .isNotEmpty) // Ensure questions exist
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${currentIndex + 1}. ${questions[currentIndex]['question']}",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        "(Marks: ${questions[currentIndex]['marks'] ?? 0})",
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black45),
                                      ),
                                    ],
                                  ),
                                if (questions
                                    .isNotEmpty) // Ensure options exist
                                  ...['A', 'B', 'C', 'D']
                                      .where((opt) => questions[currentIndex]
                                          .containsKey('option$opt'))
                                      .map((opt) => RadioListTile<String>(
                                            title: Text(
                                                "$opt: ${questions[currentIndex]['option$opt'] ?? ''}"),
                                            value: opt,
                                            groupValue:
                                                selectedAnswers[currentIndex],
                                            onChanged: isTestCompleted
                                                ? null
                                                : (value) {
                                                    setState(() {
                                                      selectedAnswers[
                                                          currentIndex] = value;
                                                    });
                                                  },
                                          )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (currentIndex > 0)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue, Colors.purple],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: () =>
                                      setState(() => currentIndex--),
                                  child: const Text("Previous"),
                                ),
                              ),
                            if (currentIndex < questions.length - 1)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue, Colors.purple],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: () =>
                                      setState(() => currentIndex++),
                                  child: const Text("Next"),
                                ),
                              ),
                            if (currentIndex == questions.length - 1)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue, Colors.purple],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: autoSubmitTest,
                                  child: const Text("Submit"),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
    );
  }
}
