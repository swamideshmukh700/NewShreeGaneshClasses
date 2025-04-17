// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAddStudentPage extends StatefulWidget {
  const AdminAddStudentPage({super.key});

  @override
  _AdminAddStudentPageState createState() => _AdminAddStudentPageState();
}

class _AdminAddStudentPageState extends State<AdminAddStudentPage> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  String selectedClass = "";
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  List<String> classNames = [];

  @override
  void initState() {
    super.initState();
    fetchClassNames();
  }

  Future<void> fetchClassNames() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('class').get();
    setState(() {
      classNames =
          querySnapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<bool> checkUsernameExists(String username) async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('students')
        .where('userName', isEqualTo: username)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  void addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final String fullName = _fullNameController.text.trim();
    final String userName = _userNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    bool exists = await checkUsernameExists(userName);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This username is already taken.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('students').add({
        'fullName': fullName,
        'userName': userName,
        'email': email,
        'password': password,
        'class': selectedClass,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error adding student: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
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
          'Add Student',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child :SingleChildScrollView(
        child: Card(
          elevation: 8, // Shadow effect
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: 250, // Make form compact
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter full name'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Username
                    TextFormField(
                      controller: _userNameController,
                      decoration: const InputDecoration(labelText: 'User Name'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter username'
                          : null,
                    ),
                    const SizedBox(height: 15),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        if (!value.endsWith('@gmail.com')) {
                          return 'Only Gmail accounts are allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Class Dropdown
                    classNames.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: selectedClass.isEmpty ? null : selectedClass,
                            items: classNames
                                .map((className) => DropdownMenuItem(
                                      value: className,
                                      child: Text(className),
                                    ))
                                .toList(),
                            decoration:
                                const InputDecoration(labelText: 'Class'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Select a class'
                                : null,
                            onChanged: (value) {
                              setState(() {
                                selectedClass = value!;
                              });
                            },
                          ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: SizedBox(
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
                            onPressed: _isLoading ? null : addStudent,
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
                                        'Add',
                                        style: TextStyle(fontSize: 18),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
