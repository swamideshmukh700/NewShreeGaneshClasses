// ignore_for_file: avoid_print, unused_local_variable, unused_element, prefer_interpolation_to_compose_strings, deprecated_member_use

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:shri_ganesh_classes/widgets/bottom_navigation.dart';
import 'package:shri_ganesh_classes/widgets/custom_app_bar.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:intl/intl.dart';

class UserViewViedo extends StatefulWidget {
  final String studentEmail;
  final String studentId; //  Add these as final variables
  final String studentClass;

  const UserViewViedo({
    super.key,
    required this.studentEmail,
    required this.studentId, //  Now properly stored
    required this.studentClass,
    //  Now properly stored
  });

  @override
  _UserViewViedoState createState() => _UserViewViedoState();
}

class _UserViewViedoState extends State<UserViewViedo> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Add scaffold key
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final Map<String, bool> _isVideoVisible = {};
  DateTime? selectedDate;

  String? studentClass;
  bool isLoading = true;
  List<Map<String, dynamic>> vedios = [];
  Set<String> expandedVedios = {};
  List<Map<String, dynamic>> filteredVedios = [];
  String searchQuery = "";
  final FocusNode _searchFocusVedios = FocusNode();


  @override
  void initState() {
    super.initState();
    _fetchStudentClassAndVeidos();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Foreground message received!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('🔔 Notification: ${message.notification}');
    }
  });
  }

  @override
  void dispose() {
    _searchFocusVedios.dispose();

    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var chewie in _chewieControllers.values) {
      chewie.dispose();
    }
    super.dispose();
  }

  void _filterByDate(DateTime date) {
    setState(() {
      selectedDate = date;
      filteredVedios = vedios.where((veido) {
        DateTime veidoDate = veido['date'];
        return veidoDate.year == date.year &&
            veidoDate.month == date.month &&
            veidoDate.day == date.day;
      }).toList();
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _filterByDate(picked);
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

  Future<void> _fetchStudentClassAndVeidos() async {
    try {
      QuerySnapshot studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: widget.studentEmail)
          .limit(1)
          .get();
      if (studentQuery.docs.isEmpty) {
        // Try fetching by userName instead
        studentQuery = await FirebaseFirestore.instance
            .collection('students')
            .where('userName', isEqualTo: widget.studentEmail)
            .limit(1)
            .get();
      }

      if (studentQuery.docs.isNotEmpty) {
        var studentData =
            studentQuery.docs.first.data() as Map<String, dynamic>;

        String studentClass = studentData['class']?.toString().trim() ?? '';

        setState(() {
          this.studentClass = studentClass;
        });

        if (studentClass.isEmpty) {
          setState(() => isLoading = false);
          return;
        }

        // Fetch vedios
        QuerySnapshot vediosQuery = await FirebaseFirestore.instance
            .collection('vedios')
            .where('class', isEqualTo: studentClass)
            .get();
        List<Map<String, dynamic>> fetchedNotes = vediosQuery.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return {
            'name': data['name'],
            'link': data['link'],
            'date': data['date'] is Timestamp
                ? (data['date'] as Timestamp)
                    .toDate() // Convert Firestore Timestamp to DateTime
                : DateTime.parse(data[
                    'date']), // Convert String date (yyyy-MM-dd) to DateTime
            'id': doc.id,
            'expanded': false,
          };
        }).toList();

// 🔹 Sorting Notes by Date (Latest First)
        fetchedNotes.sort((a, b) => b['date'].compareTo(a['date']));

        setState(() {
          vedios = fetchedNotes;
          filteredVedios = fetchedNotes;
          isLoading = false;
        });
      } else {
        print('No student found with this email or userName');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  void _searchVeido(String query) {
    setState(() {
      searchQuery = query;
      filteredVedios = vedios
          .where((veidos) =>
              veidos['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// 🔹 Function to Build Drawer Item
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign key to Scaffold
      appBar: CustomAppBar(
        title: "View Veido",
        scaffoldKey: _scaffoldKey,
        email: widget.studentEmail,
        onLogout: () {},
      ),

      bottomNavigationBar: BottomNavigation(
        email: widget.studentEmail,
        studentId: widget.studentId,
        selectedIndex: 0, // Change based on the current page
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      // Search Box
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                            ),
                          ),
                          padding:
                              const EdgeInsets.all(1), // Gradient border effect
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: TextField(
                              onChanged: _searchVeido,
                              focusNode: _searchFocusVedios,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 15), // less horizontal padding
                                hintText: "Search vedios...",
                                hintStyle: TextStyle(fontSize: 16),
                                border: InputBorder.none,
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Calendar Icon + Date Text
                      // Calendar Icon + Date Text
                      Container(
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ),
                        ),
                        padding:
                            const EdgeInsets.all(1), // Gradient border effect
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: InkWell(
                            onTap: () => _pickDate(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.black, size: 20),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    selectedDate != null
                                        ? DateFormat('dd MMM yy')
                                            .format(selectedDate!)
                                        : 'Select Date',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (selectedDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 18, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        selectedDate = null;
                                        filteredVedios = vedios;
                                      });
                                    },
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filteredVedios.isEmpty
                      ? const Center(
                          child: Text(
                            "No vedios found",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredVedios.length,
                          itemBuilder: (context, index) {
                            var veido = filteredVedios[index];
                            String id = veido['id'];
                            String name = veido['name'];
                            String link = veido['link'];
                            bool isVisible = _isVideoVisible[id] ?? false;

                            return FutureBuilder(
                              future: _initializeController(id, link),
                              builder: (context, snapshot) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "${index + 1}. $name",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _isVideoVisible
                                                      .forEach((key, _) {
                                                    if (key != id) {
                                                      _isVideoVisible[key] =
                                                          false;
                                                      _controllers[key]
                                                          ?.pause();
                                                    }
                                                  });
                                                  _isVideoVisible[id] =
                                                      !isVisible;
                                                  if (_isVideoVisible[id] ==
                                                      true) {
                                                    _controllers[id]?.play();
                                                  } else {
                                                    _controllers[id]?.pause();
                                                  }
                                                });
                                              },
                                              child: Text(isVisible
                                                  ? "Close Video"
                                                  : "View Video"),
                                            ),
                                          ],
                                        ),
                                        if (isVisible)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 12),
                                            child: _controllers[id] == null ||
                                                    !_controllers[id]!
                                                        .value
                                                        .isInitialized
                                                ? const Center(
                                                    child:
                                                        CircularProgressIndicator())
                                                : AspectRatio(
                                                    aspectRatio:
                                                        _controllers[id]!
                                                            .value
                                                            .aspectRatio,
                                                    child: Chewie(
                                                      controller:
                                                          _chewieControllers
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
                        ),
                ),
              ],
            ),
    );
  }
}
