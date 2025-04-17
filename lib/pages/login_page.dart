// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shri_ganesh_classes/pages/admin_card_demo_screen.dart';
import 'package:shri_ganesh_classes/pages/user_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
    _getFCMToken();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🟢 Opened from background");
      if (message.notification != null) {
        print("Title: ${message.notification!.title}");
        print("Body: ${message.notification!.body}");

        // Optional: Alert dialog or navigation logic
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(message.notification!.title ?? "Notification"),
            content: Text(message.notification!.body ?? ""),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print("FCM Token: $token");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userType = prefs.getString('userType');
    String? email = prefs.getString('email');
    print("UserType: $userType, Email: $email");

    if (userType == 'student') {
      final docRef =
          FirebaseFirestore.instance.collection('students').doc(email);

      docRef.get().then((doc) {
        if (doc.exists) {
          // 🔄 Document exists, update token
          docRef.update({'fcmToken': token});
        } else {
          // 🆕 Document doesn't exist, create new document with basic data
          docRef.set({
            'email': email,
            'fcmToken': token,
            'name': '', // Optional: you can remove or set later
            'class': prefs.getString('studentClass') ?? '',
          });
        }
      }).catchError((error) {
        print("Error checking Firestore document: $error");
      });
    }
  }

  Future<void> _checkLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    String? userType = prefs.getString('userType');

    if (isLoggedIn == true) {
      if (userType == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminCardDemoScreen()),
        );
      } else if (userType == 'student') {
        // ✅ User Data Load Kara
        String? email = prefs.getString('email');
        String? studentClass = prefs.getString('studentClass');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserDashboardPage(
              email: email ?? '',
              studentClass: studentClass ?? '',
            ),
          ),
        );
      }
    }
  }

  Future<void> _checkLogin() async {
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // **Admin Login**
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: input) // Fixed syntax
          .where('password', isEqualTo: password)
          .get();
      if (adminSnapshot.docs.isNotEmpty) {
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', 'admin');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminCardDemoScreen()),
        );
        return;
      }

      // **Student Login**
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where(Filter.or(
            Filter("email", isEqualTo: input),
            Filter("userName", isEqualTo: input),
          ))
          .where('password', isEqualTo: password)
          .get();

      if (studentSnapshot.docs.isNotEmpty) {
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', 'student');
        // ✅ User Data Save Kara
        String studentEmail = studentSnapshot.docs[0]['email'];
        String studentClass = studentSnapshot.docs[0]['class'];
        await prefs.setString('email', studentEmail);
        await prefs.setString('studentClass', studentClass);
        // ✅ आता prefs सेट झालेत, इथे call कर
        await _getFCMToken();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserDashboardPage(
              email: studentEmail,
              studentClass: studentClass,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple], // Background gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Container(
                width: screenWidth < 400
                    ? screenWidth * 0.85
                    : 350, // Adjust width for mobile
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Login Button
                    SizedBox(
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
                        onPressed: _isLoading ? null : _checkLogin,
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
                                    'Login',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
