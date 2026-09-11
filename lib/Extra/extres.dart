// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMarksWithPermissions extends StatefulWidget {
  final String cnic;

  const AddMarksWithPermissions({super.key, required this.cnic});

  @override
  State<AddMarksWithPermissions> createState() =>
      _AddMarksWithPermissionsState();
}

class _AddMarksWithPermissionsState extends State<AddMarksWithPermissions> {
  String? _selectedClass;
  String? _selectedSection;
  List<String> _availableClasses = [];
  List<String> _availableSections = [];

  bool _isLoading = true;
  bool _canEnterMarks = false;

  List<Map<String, String>> _assignedClassSections = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherPermissions();
  }

  Future<void> _loadTeacherPermissions() async {
    try {
      DocumentSnapshot teacherDoc =
          await FirebaseFirestore.instance
              .collection('Teachers')
              .doc('Teacher${widget.cnic}')
              .get();

      if (teacherDoc.exists) {
        var data = teacherDoc.data() as Map<String, dynamic>;
        _canEnterMarks = data['canEnterMarks'] ?? false;

        if (_canEnterMarks) {
          List assigned = data['assignedClasses'] ?? [];
          _assignedClassSections = List<Map<String, String>>.from(
            assigned.map((e) => Map<String, String>.from(e)),
          );

          // Extract unique classes
          _availableClasses =
              _assignedClassSections.map((e) => e['class']!).toSet().toList();
        }
      }
    } catch (e) {
      print("Error loading teacher permissions: $e");
    }

    setState(() => _isLoading = false);
  }

  void _loadSectionsForSelectedClass() {
    if (_selectedClass == null) return;

    final classSections =
        _assignedClassSections
            .where((e) => e['class'] == _selectedClass)
            .map((e) => e['section']!)
            .toList();

    if (classSections.contains('All')) {
      // Load all real sections from Firestore
      FirebaseFirestore.instance
          .collection('Classes')
          .doc(_selectedClass)
          .collection('Sections')
          .get()
          .then((snapshot) {
            final allSections = snapshot.docs.map((doc) => doc.id).toList();
            setState(() {
              _availableSections = ['All'] + allSections;
              _selectedSection = 'All';
            });
          });
    } else {
      setState(() {
        _availableSections = classSections;
        _selectedSection = null;
      });
    }
  }

  Future<void> _showMarkEntryDialog(
    String studentId,
    String studentName,
  ) async {
    TextEditingController subjectController = TextEditingController();
    TextEditingController obtainedMarksController = TextEditingController();
    TextEditingController totalMarksController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Enter Marks for $studentName"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: "Subject Name"),
                ),
                TextField(
                  controller: obtainedMarksController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Obtained Marks",
                  ),
                ),
                TextField(
                  controller: totalMarksController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Total Marks"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String subject = subjectController.text.trim();
                  int? obtained = int.tryParse(
                    obtainedMarksController.text.trim(),
                  );
                  int? total = int.tryParse(totalMarksController.text.trim());

                  if (subject.isNotEmpty && obtained != null && total != null) {
                    await FirebaseFirestore.instance
                        .collection('Classes')
                        .doc(_selectedClass)
                        .collection('Sections')
                        .doc(
                          _selectedSection == 'All'
                              ? 'Default'
                              : _selectedSection!,
                        )
                        .collection('Students')
                        .doc(studentId)
                        .set({
                          'marks': {
                            subject: {'obtained': obtained, 'total': total},
                          },
                        }, SetOptions(merge: true));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Marks added for $studentName")),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_canEnterMarks) {
      return const Scaffold(
        body: Center(child: Text("You do not have permission to enter marks.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Add Marks (With Permissions)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: const InputDecoration(labelText: "Select Class"),
              items:
                  _availableClasses
                      .map(
                        (cls) => DropdownMenuItem(value: cls, child: Text(cls)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClass = value;
                  _selectedSection = null;
                  _availableSections = [];
                });
                _loadSectionsForSelectedClass();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedSection,
              decoration: const InputDecoration(labelText: "Select Section"),
              items:
                  _availableSections
                      .map(
                        (sec) => DropdownMenuItem(
                          value: sec,
                          child: Text(
                            sec == 'All' ? "All Sections" : "Section $sec",
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSection = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  (_selectedClass != null && _selectedSection != null)
                      ? StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('Classes')
                                .doc(_selectedClass)
                                .collection('Sections')
                                .doc(
                                  _selectedSection == 'All'
                                      ? 'Default'
                                      : _selectedSection!,
                                )
                                .collection('Students')
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          var students = snapshot.data!.docs;
                          if (students.isEmpty) {
                            return const Center(
                              child: Text("No students found."),
                            );
                          }

                          return ListView.builder(
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              var student = students[index];
                              String name = student['name'] ?? '';
                              String roll = student['rollNumber'] ?? '';

                              return Card(
                                child: ListTile(
                                  title: Text(name),
                                  subtitle: Text("Roll Number: $roll"),
                                  trailing: ElevatedButton(
                                    onPressed:
                                        () => _showMarkEntryDialog(
                                          student.id,
                                          name,
                                        ),
                                    child: const Text("Enter Marks"),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                      : const Center(
                        child: Text("Please select class and section."),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
