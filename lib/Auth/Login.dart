// ignore_for_file: use_super_parameters, file_names, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:workit/Auth/forget.dart';
import 'package:workit/Components/MovingText.dart';
import 'package:workit/Home/NavBar.dart';
import 'package:workit/Widgets/AdminButton.dart';
import '../Components/Cnicfield.dart';
import '../Components/RotateImage.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({Key? key}) : super(key: key);

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  void _showMessage(String msg, {bool isError = false}) {
    // Clear previous SnackBar before showing a new one
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show both Toast and SnackBar
    Fluttertoast.showToast(
      msg: msg,
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor:
          isError ? const Color(0xFF8A0204) : const Color(0xFF1B7FEE),
      textColor: Colors.white,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFF8A0204) : const Color(0xFF1B7FEE),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loginTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final cnic = _cnicController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final docRef = _firestore.collection('Teachers').doc('Teacher$cnic');
      final teacherDoc = await docRef.get();

      if (!teacherDoc.exists) {
        _showMessage('❌ No teacher found with this CNIC.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final email = teacherDoc['email'];
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      _showMessage('✅ Login Successfully!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          errorMsg = '❌ User not found. Please check CNIC or contact admin.';
          break;
        case 'wrong-password':
          errorMsg = '🔒 Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMsg = '⚠️ Invalid email associated with this CNIC.';
          break;
        case 'user-disabled':
          errorMsg = '⛔ This account has been disabled.';
          break;
        default:
          errorMsg = '🚫 ${e.message ?? 'Authentication failed'}';
      }
      _showMessage(errorMsg, isError: true);
    } catch (e) {
      _showMessage('⚠️ Unexpected error occurred: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Row(
              children: [
                PassButton(),
                Expanded(
                  child: AnimatedMovingText(
                    text: 'Noble School System and College',
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Teacher Login",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8a0204),
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 35),
                  const RotatingEarthLogo(size: 200),
                  const SizedBox(height: 40),
                  InputText(
                    mycontroller: _cnicController,
                    onvalidate: (value) {
                      if (value == null || value.isEmpty) return 'Enter CNIC';
                      if (value.length != 15)
                        return 'CNIC must be 15 characters (with dashes)';
                      return null;
                    },
                    onsubmit: (value) {},
                    keyboard: TextInputType.number,
                    hint: 'Enter CNIC (e.g., 31000-1234567-8)',
                    Cursor: true,
                    isCNIC: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Enter Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator:
                        (value) => value!.isEmpty ? 'Enter password' : null,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forget Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 96),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loginTeacher,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
