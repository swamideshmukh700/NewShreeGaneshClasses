// ignore_for_file: use_build_context_synchronously, use_super_parameters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shri_ganesh_classes/pages/admin_add_question.dart';
import 'package:shri_ganesh_classes/pages/admin_edit_question_page.dart';

class AdminQuestionListPage extends StatefulWidget {
  final String testId;
  const AdminQuestionListPage({Key? key, required this.testId}) : super(key: key);

  @override
  _AdminQuestionListPageState createState() => _AdminQuestionListPageState();
}

class _AdminQuestionListPageState extends State<AdminQuestionListPage> {
  Color appBarTitleColor = Colors.white;
  Color backArrowColor = Colors.white;
  Color addIconColor = Colors.white;
  final CollectionReference questionCollection =
      FirebaseFirestore.instance.collection('questions');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                "Question List",
                style: TextStyle(
                  color: appBarTitleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent, // Transparent to show gradient
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
                icon: Icon(Icons.arrow_back, color: backArrowColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              MouseRegion(
                onEnter: (_) {
                  setState(() {
                    addIconColor = Colors.orange;
                  });
                },
                onExit: (_) {
                  setState(() {
                    addIconColor = Colors.white;
                  });
                },
                child: IconButton(
                  icon: Icon(Icons.add,
                      color: addIconColor), // Plus icon with hover effect
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            QuestionAddPage(testId: widget.testId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: questionCollection
            .where('testId', isEqualTo: widget.testId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data?.docs ?? [];

          if (questions.isEmpty) {
            return const Center(child: Text('No questions available.'));
          }

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              var questionDoc = questions[index];
              var questionData =
                  questionDoc.data() as Map<String, dynamic>? ?? {};

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  title: Text(
                    questionData['question'] ?? 'No Question',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A: ${questionData['optionA'] ?? 'N/A'}'),
                      Text('B: ${questionData['optionB'] ?? 'N/A'}'),
                      Text('C: ${questionData['optionC'] ?? 'N/A'}'),
                      Text('D: ${questionData['optionD'] ?? 'N/A'}'),
                      Text(
                          'Correct Answer: ${questionData['correctAnswer'] ?? 'N/A'}'),
                      Text('Marks: ${questionData['marks'] ?? '0'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: Colors.green,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditQuestionPage(
                                questionId: questionDoc.id, // Question ID
                                questionData: questionData, // Question Data
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
