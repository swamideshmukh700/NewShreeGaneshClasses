// ignore_for_file: deprecated_member_use, unused_element, avoid_print, unnecessary_import, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shri_ganesh_classes/pages/admin_edit_vedio_page.dart';
import 'package:shri_ganesh_classes/pages/app_drawer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class AdminVedioListPage extends StatefulWidget {
  const AdminVedioListPage({super.key});

  @override
  State<AdminVedioListPage> createState() => _AdminVedioListPageState();
}

class _AdminVedioListPageState extends State<AdminVedioListPage> {
  final vediosRef = FirebaseFirestore.instance.collection('vedios');
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, bool> _isVideoVisible = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Map<String, bool> _isMuted = {};
  String? selectedClass;
  List<String> classList = [];

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    var classSnapshot = await _firestore.collection('class').get();
    setState(() {
      classList = ['Select Class']; // <-- Add a default item
      classList.addAll(
          classSnapshot.docs.map((doc) => doc['name'] as String).toList());
      selectedClass = 'Select Class';
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var chewie in _chewieControllers.values) {
      chewie.dispose();
    }
    super.dispose();
  }

  Future<void> deleteVideo(String docId, String videoUrl) async {
    try {
      // Delete from Firestore
      await FirebaseFirestore.instance.collection('vedios').doc(docId).delete();

      // Delete from Storage
      final storageRef = FirebaseStorage.instance.refFromURL(videoUrl);
      await storageRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video deleted successfully!')),
      );
    } catch (e) {
      print('Delete Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting video: $e')),
      );
    }
  }

  Future<void> _initializeController(String id, String link) async {
    if (!_controllers.containsKey(id)) {
      try {
        final controller = VideoPlayerController.network(link);
        await controller.initialize();
        _controllers[id] = controller;

        controller.addListener(() {
          setState(() {});
          if (controller.value.position >= controller.value.duration) {
            controller.pause();
            controller.seekTo(Duration.zero);
          }
        });
      } catch (e) {
        print("Error initializing video for $id: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(onSelectPage: (widget) {}),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient:
                    const LinearGradient(colors: [Colors.blue, Colors.purple]),
              ),
              padding: const EdgeInsets.all(2),
              child: DropdownButtonFormField<String>(
                value: selectedClass,
                items: classList.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != 'Select Class') {
                    setState(() {
                      selectedClass = newValue!;
                    });
                  }
                },
              )),
          Expanded(
            child: StreamBuilder(
              stream: (selectedClass != null && selectedClass != 'Select Class')
                  ? vediosRef
                      .where('class', isEqualTo: selectedClass)
                      .snapshots()
                  : vediosRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final vedios = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: vedios.length,
                  itemBuilder: (context, index) {
                    var vedio = vedios[index];
                    String id = vedio.id;
                    String link = vedio['link'];
                    String name = vedio['name'];

                    return FutureBuilder(
                      future: _initializeController(id, link),
                      builder: (context, snap) {
                        bool isVisible = _isVideoVisible[id] ?? false;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${index + 1}. $name",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isVideoVisible.forEach((key, _) {
                                            if (key != id) {
                                              _isVideoVisible[key] = false;
                                              _controllers[key]?.pause();
                                            }
                                          });
                                          _isVideoVisible[id] = !isVisible;
                                          if (_isVideoVisible[id] == true) {
                                            _controllers[id]?.play();
                                          } else {
                                            _controllers[id]?.pause();
                                          }
                                        });
                                      },
                                      child: Text(
                                        isVisible
                                            ? "Close Video"
                                            : "View Video",
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AdminEditVedioPage(
                                              id: vedio.id,
                                              name: name,
                                              videoUrl: link,
                                              studentClass: vedio['class'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        await deleteVideo(id, link);
                                      },
                                    ),
                                  ],
                                ),
                                if (isVisible)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _controllers[id] == null ||
                                            !_controllers[id]!
                                                .value
                                                .isInitialized
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : AspectRatio(
                                            aspectRatio: _controllers[id]!
                                                .value
                                                .aspectRatio,
                                            child: Chewie(
                                              controller: _chewieControllers
                                                  .putIfAbsent(
                                                id,
                                                () => ChewieController(
                                                  videoPlayerController:
                                                      _controllers[id]!,
                                                  autoPlay: true,
                                                  looping: false,
                                                ),
                                              ),
                                            ),
                                          ),
                                  )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
