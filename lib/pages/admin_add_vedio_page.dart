// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminAddVedioPage extends StatefulWidget {
  const AdminAddVedioPage({super.key});

  @override
  State<AdminAddVedioPage> createState() => _AdminAddVedioPageState();
}

class _AdminAddVedioPageState extends State<AdminAddVedioPage> {
  final nameController = TextEditingController();
  String? uploadedVideoUrl;
  bool isUploading = false;

  final vediosRef = FirebaseFirestore.instance.collection('vedios');
  String? selectedClass;
  List<String> classList = [];

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('class').get();

    setState(() {
      classList = snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  Future<void> pickAndUploadVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.single.path != null) {
      setState(() {
        isUploading = true;
      });

      try {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final file = File(filePath);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('vedios/${DateTime.now().millisecondsSinceEpoch}_$fileName');

        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        setState(() {
          uploadedVideoUrl = downloadUrl;
          isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully')),
        );
      } catch (e) {
        print('Upload Error: $e');
        setState(() {
          isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video upload failed')),
        );
      }
    } else {
      print('No video selected or file path is null.');
    }
  }

  void addVedio() async {
    final name = nameController.text.trim();
    if (name.isEmpty || uploadedVideoUrl == null || selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    await vediosRef.add({
      'name': name,
      'link': uploadedVideoUrl,
      'class': selectedClass,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),

    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video added successfully!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Video'),
        centerTitle: true,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Video Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedClass,
              items: classList.map((className) {
                return DropdownMenuItem(
                  value: className,
                  child: Text(className),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClass = value;
                });
              },
              decoration: const InputDecoration(
                labelText: "Select Class",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isUploading ? null : pickAndUploadVideo,
              child: Text(isUploading ? 'Uploading...' : 'Upload Video'),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 150,
              height: 60,
              child: ElevatedButton(
                onPressed:
                    uploadedVideoUrl != null && !isUploading ? addVedio : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(0),
                  foregroundColor: Colors.white,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                ),
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
                      'Add Video',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
