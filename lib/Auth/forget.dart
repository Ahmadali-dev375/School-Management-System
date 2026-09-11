// ignore_for_file: use_super_parameters, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:workit/Components/Cnicfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _cnicController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cnic = _cnicController.text.trim(); // keep dashes
    final docId = 'Teacher$cnic';

    try {
      DocumentSnapshot teacherDoc =
          await _firestore.collection('Teachers').doc(docId).get();

      if (!teacherDoc.exists) {
        Fluttertoast.showToast(msg: 'No teacher found with this CNIC.');
        setState(() => _isLoading = false);
        return;
      }

      final email = teacherDoc.get('email');

      if (email == null || email.toString().isEmpty) {
        Fluttertoast.showToast(msg: 'No email found for this CNIC.');
        setState(() => _isLoading = false);
        return;
      }

      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(msg: 'Password reset email sent to $email.');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? 'Failed to send reset email.');
    } catch (e) {
      Fluttertoast.showToast(msg: 'An unexpected error occurred.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Forgot Password')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Your custom InputText widget (with dashed CNIC support)
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
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Reset Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
