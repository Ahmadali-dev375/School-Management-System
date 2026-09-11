// ignore_for_file: curly_braces_in_flow_control_structures, prefer_final_fields, use_super_parameters, file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../Components/Cnicfield.dart';
import '../Components/Phnfield.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({Key? key}) : super(key: key);

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _fatherController = TextEditingController();

  String? _selectedGender;
  bool _isLoading = false;

  List<String> _allClasses = [];
  List<String> _allSections = [];
  List<Map<String, String?>> _selectedClassSectionPairs = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final classesSnapshot = await _firestore.collection('Classes').get();
      setState(() {
        _allClasses = classesSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load classes.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _loadSectionsForClass(String className) async {
    try {
      final sectionSnapshot =
          await _firestore
              .collection('Classes')
              .doc(className)
              .collection('Sections')
              .get();

      return sectionSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  void _addClassSectionPair() {
    setState(() {
      _selectedClassSectionPairs.add({"class": null, "section": null});
    });
  }

  void _removeClassSectionPair(int index) {
    setState(() {
      _selectedClassSectionPairs.removeAt(index);
    });
  }

  Future<void> _registerTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final name = _nameController.text.trim();
    final cnic = _cnicController.text.trim();
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final contact = _contactController.text.trim();
    final address = _addressController.text.trim();
    final father = _fatherController.text.trim();
    final gender = _selectedGender;

    final password = cnic;

    try {
      final existingTeacher =
          await _firestore.collection('Teachers').doc("Teacher$cnic").get();
      if (existingTeacher.exists) {
        Fluttertoast.showToast(
          msg: 'Teacher with this CNIC already exists.',
          backgroundColor: Colors.red,
        );
        return;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      final assignedClasses =
          _selectedClassSectionPairs
              .where((pair) => pair['class'] != null)
              .map(
                (pair) => {
                  'class': pair['class'],
                  'section': pair['section'], // could be null
                },
              )
              .toList();

      await _firestore.collection('Teachers').doc("Teacher$cnic").set({
        'uid': uid,
        'name': name,
        'Father': father,
        'cnic': cnic,
        'email': email,
        'gender': gender,
        'subject': subject,
        'contact': contact,
        'address': address,
        'assignedClasses': assignedClasses,
      });

      Fluttertoast.showToast(
        msg: '✅ Teacher $name registered!',
        backgroundColor: Colors.blue,
      );
      _clearForm();
    } on FirebaseAuthException catch (e) {
      String msg = switch (e.code) {
        'email-already-in-use' => 'Email already in use.',
        'invalid-email' => 'Invalid email format.',
        'weak-password' => 'CNIC is too weak as a password.',
        _ => 'FirebaseAuth error: ${e.message}',
      };
      Fluttertoast.showToast(msg: msg, backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _cnicController.clear();
    _emailController.clear();
    _subjectController.clear();
    _contactController.clear();
    _addressController.clear();
    _fatherController.clear();
    setState(() {
      _selectedGender = null;
      _selectedClassSectionPairs.clear();
    });
  }

  Widget _buildClassSectionPair(int index) {
    final current = _selectedClassSectionPairs[index];
    final selectedClass = current['class'];
    final selectedSection = current['section'];

    return FutureBuilder<List<String>>(
      future:
          selectedClass != null
              ? _loadSectionsForClass(selectedClass)
              : Future.value([]),
      builder: (context, snapshot) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _allClasses
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: (value) async {
                      final updatedSections = await _loadSectionsForClass(
                        value!,
                      );
                      setState(() {
                        _selectedClassSectionPairs[index]['class'] = value;
                        _selectedClassSectionPairs[index]['section'] =
                            updatedSections.contains(selectedSection)
                                ? selectedSection
                                : null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child:
                      snapshot.connectionState == ConnectionState.waiting
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<String>(
                            value: selectedSection,
                            decoration: const InputDecoration(
                              labelText: 'Section (optional)',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                snapshot.data!
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text("Section $s"),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(
                                () =>
                                    _selectedClassSectionPairs[index]['section'] =
                                        value,
                              );
                            },
                          ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeClassSectionPair(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Register Teacher')),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) => value!.isEmpty ? 'Enter name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fatherController,
                          decoration: const InputDecoration(
                            labelText: 'Father/Husband',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Enter Father/Husband'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        InputText(
                          mycontroller: _cnicController,
                          onvalidate: (value) {
                            if (value == null || value.isEmpty)
                              return 'Enter CNIC';
                            if (value.length != 15)
                              return 'Invalid CNIC format';
                            return null;
                          },
                          onsubmit: (_) {},
                          keyboard: TextInputType.number,
                          hint: 'Enter CNIC (00000-0000000-0)',
                          Cursor: true,
                          isCNIC: true,
                        ),
                        const SizedBox(height: 1),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty || !value.contains('@')
                                      ? 'Enter valid email'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              ['Male', 'Female', 'Other']
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) =>
                                  setState(() => _selectedGender = value!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter subject' : null,
                        ),
                        const SizedBox(height: 16),
                        PhoneInputText(
                          mycontroller: _contactController,
                          hint: 'Enter Phone (e.g. 0300-1234567)',
                        ),
                        const SizedBox(height: 1),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter Address' : null,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const Text(
                          'Assign Class (optional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ..._selectedClassSectionPairs.asMap().entries.map(
                          (entry) => _buildClassSectionPair(entry.key),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Class'),
                            onPressed: _addClassSectionPair,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _registerTeacher,
                          child: const Text('Register Teacher'),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
