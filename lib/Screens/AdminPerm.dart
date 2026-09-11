// ignore_for_file: use_key_in_widget_constructors, file_names, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'AdminNew.dart';

class AdminTeacherPermissions extends StatefulWidget {
  @override
  _AdminTeacherPermissionsState createState() =>
      _AdminTeacherPermissionsState();
}

class _AdminTeacherPermissionsState extends State<AdminTeacherPermissions> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedTeacherCnic;
  List<Map<String, String>> _assignedClassSectionPairs = [];

  /// All available class-section combinations
  Map<String, List<String>> _classSections = {};

  @override
  void initState() {
    super.initState();
    _fetchAllClassSectionData();
  }

  void _fetchAllClassSectionData() async {
    final classesSnapshot = await _firestore.collection('Classes').get();

    Map<String, List<String>> result = {};
    for (var classDoc in classesSnapshot.docs) {
      final sectionsSnapshot =
          await _firestore
              .collection('Classes')
              .doc(classDoc.id)
              .collection('Sections')
              .get();

      List<String> sections =
          sectionsSnapshot.docs.map((doc) => doc.id).toList();
      sections.add('General'); // Add 'General' as default option
      result[classDoc.id] = sections;
    }

    setState(() {
      _classSections = result;
    });
  }

  /// Fetch current permissions from Teachers collection
  void _fetchTeacherAssignedClasses(String cnic) async {
    final doc =
        await _firestore.collection('Teachers').doc("Teacher$cnic").get();

    if (doc.exists) {
      final data = doc.data()!;
      final List<dynamic> assigned = data['assignedClasses'] ?? [];

      setState(() {
        _assignedClassSectionPairs =
            assigned
                .map<Map<String, String>>(
                  (e) => {
                    'class': e['class'] as String,
                    'section': e['section'] as String,
                  },
                )
                .toList();
      });
    }
  }

  /// Save assigned classes to Teachers collection
  void _saveAssignedClasses() async {
    if (_selectedTeacherCnic == null) {
      Fluttertoast.showToast(
        msg: "Please select a teacher.",
        backgroundColor: Color(0xFF8A0204),
      );
      return;
    }

    await _firestore
        .collection('Teachers')
        .doc("Teacher$_selectedTeacherCnic")
        .update({'assignedClasses': _assignedClassSectionPairs});

    Fluttertoast.showToast(
      msg: "Permissions updated!",
      backgroundColor: Color(0xFF1B7FEE),
    );
  }

  /// Add class-section pair
  void _addClassSectionPair(String className, String section) {
    if (!_assignedClassSectionPairs.any(
      (e) => e['class'] == className && e['section'] == section,
    )) {
      setState(() {
        _assignedClassSectionPairs.add({
          'class': className,
          'section': section,
        });
      });
    }
  }

  /// Remove class-section pair
  void _removePair(int index) {
    setState(() {
      _assignedClassSectionPairs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (_) =>
                          const ClassWisePermissionManager(), // you can pass preselectedClass if needed
                );
              },
              icon: Icon(Icons.class_),
            ),
          ],
          title: const Text("Assign Teacher"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              /// Select Teacher
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('Teachers').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  final teacherDocs = snapshot.data!.docs;

                  // Generate dropdown items
                  final teacherItems =
                      teacherDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final cnic = data['cnic'] ?? '';
                        final name = data['name'] ?? '';
                        return DropdownMenuItem<String>(
                          value: cnic,
                          child: Text("$name ($cnic)"),
                        );
                      }).toList();

                  // Ensure selected CNIC still exists
                  if (_selectedTeacherCnic != null &&
                      !teacherItems.any(
                        (item) => item.value == _selectedTeacherCnic,
                      )) {
                    _selectedTeacherCnic = null;
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select Teacher",
                    ),
                    value: _selectedTeacherCnic,
                    items: teacherItems,
                    onChanged: (value) {
                      setState(() {
                        _selectedTeacherCnic = value!;
                        _fetchTeacherAssignedClasses(
                          value,
                        ); // Corrected method call
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              /// Class and Section Selector
              if (_classSections.isNotEmpty) ...[
                const Text("Assign Class and Section:"),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Select Class"),
                  items:
                      _classSections.keys
                          .map(
                            (className) => DropdownMenuItem<String>(
                              value: className,
                              child: Text(className),
                            ),
                          )
                          .toList(),
                  onChanged: (selectedClass) {
                    if (selectedClass == null) return;

                    showDialog(
                      context: context,
                      builder: (_) {
                        final sections = _classSections[selectedClass]!;
                        return AlertDialog(
                          title: Text("Select Section"),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: sections.length,
                              itemBuilder: (context, index) {
                                final section = sections[index];
                                return ListTile(
                                  title: Text(section),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _addClassSectionPair(
                                      selectedClass,
                                      section,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),

              /// Display Selected Assigned Classes
              const Text("Assigned Classes:"),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _assignedClassSectionPairs.length,
                itemBuilder: (context, index) {
                  final entry = _assignedClassSectionPairs[index];
                  return ListTile(
                    title: Text("${entry['class']} - ${entry['section']}"),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _removePair(index),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAssignedClasses,
                child: const Text("Save Assigned Classes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
