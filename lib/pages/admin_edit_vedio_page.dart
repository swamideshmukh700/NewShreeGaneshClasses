// ignore_for_file: use_build_context_synchronously, deprecated_member_use, avoid_print, sort_child_properties_last, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

class AdminEditVedioPage extends StatefulWidget {
  final String id;
  final String name;
  final String videoUrl;
  final String studentClass;

  const AdminEditVedioPage({
    Key? key,
    required this.id,
    required this.name,
    required this.videoUrl,
    required this.studentClass,
  }) : super(key: key);

  @override
  State<AdminEditVedioPage> createState() => _AdminEditVedioPageState();
}

class _AdminEditVedioPageState extends State<AdminEditVedioPage> {
  late TextEditingController nameController;
  String? uploadedVideoUrl;
  String? selectedClass;
  List<String> classList = [];

  bool isUploading = false;
  bool _showPreview = true;
  late VideoPlayerController? _videoController;

  final vediosRef = FirebaseFirestore.instance.collection('vedios');

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    uploadedVideoUrl = widget.videoUrl;
    selectedClass = widget.studentClass;

    _videoController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
    _fetchClass();
  }

  @override
  void dispose() {
    nameController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _fetchClass() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('class').get();

      List<String> fetchedClass =
          snapshot.docs.map((doc) => doc['name'].toString()).toList();

      setState(() {
        classList = fetchedClass;

        final foundClass = classList.firstWhere(
          (cls) =>
              cls.trim().toLowerCase() ==
              widget.studentClass.trim().toLowerCase(),
          orElse: () => '',
        );

        if (foundClass.isNotEmpty) {
          selectedClass = foundClass;
        } else {
          selectedClass = classList.isNotEmpty ? classList.first : null;
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching class: $error')),
      );
    }
  }

  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      setState(() {
        isUploading = true;
      });

      try {
        // ✅ Old video delete kara if exists
        if (widget.videoUrl != null && widget.videoUrl.isNotEmpty) {
          final oldRef = FirebaseStorage.instance.refFromURL(widget.videoUrl);
          await oldRef.delete();
        }

        // ✅ New video upload kara
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        UploadTask uploadTask = FirebaseStorage.instance
            .ref()
            .child('vedios')
            .child(fileName)
            .putFile(file);

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          uploadedVideoUrl = downloadUrl;
          _videoController = VideoPlayerController.network(downloadUrl)
            ..initialize().then((_) {
              setState(() {});
            });
        });
      } catch (e) {
        print('Error: $e');
      } finally {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<void> updateVideo() async {
    String name = nameController.text.trim();
    if (name.isNotEmpty && uploadedVideoUrl != null && selectedClass != null) {
      await vediosRef.doc(widget.id).update({
        'name': name,
        'class': selectedClass,
        'link': uploadedVideoUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Video updated successfully!')),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ Please fill all fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Update Veido',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: isUploading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal))
              : ListView(
                  children: [
                    const Text(
                      'Edit Video Name',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Enter Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Class',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedClass,
                      items: classList
                          .map((className) => DropdownMenuItem(
                                value: className,
                                child: Text(className),
                              ))
                          .toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                      ),
                      onChanged: (value) =>
                          setState(() => selectedClass = value),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Old/Selected Video Preview',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _showPreview,
                          onChanged: (val) {
                            setState(() {
                              _showPreview = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    (_showPreview &&
                            uploadedVideoUrl != null &&
                            _videoController != null &&
                            _videoController!.value.isInitialized)
                        ? Column(
                            children: [
                              AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _videoController!.value.isPlaying
                                            ? _videoController!.pause()
                                            : _videoController!.play();
                                      });
                                    },
                                    child: Icon(
                                      _videoController!.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const Text('Video preview is hidden'),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Pick New Video"),
                      onPressed: pickVideo,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: updateVideo,
                      child: const Text("Update"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
