// ignore_for_file: curly_braces_in_flow_control_structures, use_super_parameters, file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Components/Cnicfield.dart';
import '../Components/Phnfield.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({Key? key}) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fatherController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();

  String? _selectedClass;
  String? _selectedSection;
  String? _selectedGender;
  List<String> _classList = [];
  List<String> _sectionList = [];
  List<String> _subjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final snapshot = await firestore.collection('Classes').get();
    setState(() {
      _classList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _loadSectionsAndSubjects(String className) async {
    final sectionSnapshot =
        await firestore
            .collection('Classes')
            .doc(className)
            .collection('Sections')
            .get();

    final classDoc = await firestore.collection('Classes').doc(className).get();
    final subjects = List<String>.from(classDoc.data()?['subjects'] ?? []);

    final newSectionList = sectionSnapshot.docs.map((doc) => doc.id).toList();

    setState(() {
      _sectionList = newSectionList;
      _subjects = subjects;

      // Retain previous selection only if still valid
      _selectedSection =
          newSectionList.contains(_selectedSection) ? _selectedSection : null;
    });
  }

  Future<bool> _isRollNumberTaken(String className, String roll) async {
    final classRef = firestore.collection('Classes').doc(className);
    final sectionsSnapshot = await classRef.collection('Sections').get();

    for (var sectionDoc in sectionsSnapshot.docs) {
      final studentsSnapshot =
          await classRef
              .collection('Sections')
              .doc(sectionDoc.id)
              .collection('Students')
              .where('rollNumber', isEqualTo: roll)
              .get();

      if (studentsSnapshot.docs.isNotEmpty) {
        return true; // Found a student with this roll number
      }
    }

    return false; // No duplicate found
  }

  Future<void> _addStudent() async {
    final name = _nameController.text.trim();
    final roll = _rollController.text.trim();
    final father = _fatherController.text.trim();
    final address = _addressController.text.trim();
    final cnic = _cnicController.text.trim();
    final gender = _selectedGender;

    if (name.isEmpty ||
        roll.isEmpty ||
        father.isEmpty ||
        _selectedClass == null) {
      _showDialog("Validation Error", "Please fill in all required fields.");
      return;
    }
    if (_selectedGender == null) {
      _showDialog("Validation Error", "Please select a gender.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🚫 Check for duplicate roll number
      final isTaken = await _isRollNumberTaken(_selectedClass!, roll);
      if (isTaken) {
        _showDialog(
          "Duplicate Roll Number",
          "This roll number already exists in the selected class.",
        );
        setState(() => _isLoading = false);
        return;
      }

      final classDocRef = firestore.collection('Classes').doc(_selectedClass);
      final sectionName =
          _selectedSection?.trim().isNotEmpty == true
              ? _selectedSection!
              : 'General';
      final sectionDocRef = classDocRef.collection('Sections').doc(sectionName);

      await sectionDocRef.set({}, SetOptions(merge: true));

      final studentRef = sectionDocRef.collection('Students').doc();

      await studentRef.set({
        'name': name,
        'rollNumber': roll,
        'fatherName': father,
        'Address': address,
        'phone': _phoneController.text.trim(),
        'class': _selectedClass,
        'section': sectionName,
        'Gender': gender,
        'cnic': cnic,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showDialog("Success", "Student added successfully.");

      _nameController.clear();
      _rollController.clear();
      _phoneController.clear();
      _fatherController.clear();
      _addressController.clear();
      _cnicController.clear();
      setState(() {
        // Only reset section if the class was changed or if no sections exist
        if (_sectionList.isEmpty) {
          _selectedSection = null;
        }
      });
    } catch (e) {
      _showDialog("Error", "Failed to add student: $e");
    }

    setState(() => _isLoading = false);
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Add Student")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Class Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Select Class",
                  border: OutlineInputBorder(),
                ),
                value: _selectedClass,
                items:
                    _classList
                        .map(
                          (className) => DropdownMenuItem(
                            value: className,
                            child: Text(className),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() => _selectedClass = value);
                  if (value != null) {
                    _loadSectionsAndSubjects(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Section Dropdown
              if (_sectionList.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Select Section (optional)",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSection,
                  items:
                      _sectionList
                          .map(
                            (section) => DropdownMenuItem(
                              value: section,
                              child: Text(section),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() => _selectedSection = value);
                  },
                ),
              if (_sectionList.isNotEmpty) const SizedBox(height: 16),
              const SizedBox(height: 16),
              // Student name & roll
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Student Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fatherController,
                decoration: const InputDecoration(
                  labelText: "Father Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rollController,
                decoration: const InputDecoration(
                  labelText: "Roll Number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              PhoneInputText(
                mycontroller: _phoneController,
                hint: 'Enter Phone (e.g. 0300-1234567)',
              ),
              //
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InputText(
                mycontroller: _cnicController,
                onvalidate: (value) {
                  if (value == null || value.isEmpty)
                    return 'Enter CNIC or B.form (Optional)';
                  if (value.length != 15) return 'Invalid CNIC format';
                  return null;
                },
                onsubmit: (_) {},
                keyboard: TextInputType.number,
                hint: 'Enter CNIC (00000-0000000-0) [Optional]',
                Cursor: true,
                isCNIC: true,
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
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 24),

              // Subjects info
              if (_subjects.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Subjects in this Class:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: _subjects.map((s) => Chip(label: Text(s))).toList(),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _isLoading ? null : _addStudent,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Add Student"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// student
