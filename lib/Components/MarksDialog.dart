// ignore_for_file: use_super_parameters, file_names, avoid_print, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnterMarksDialog extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String selectedClass;
  final String selectedSection;

  const EnterMarksDialog({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.selectedClass,
    required this.selectedSection,
  }) : super(key: key);

  @override
  _EnterMarksDialogState createState() => _EnterMarksDialogState();
}

class _EnterMarksDialogState extends State<EnterMarksDialog> {
  final TextEditingController _obtainedMarksController =
      TextEditingController();
  final TextEditingController _totalMarksController = TextEditingController();

  List<String> subjects = [];
  Set<String> filledSubjects = {};
  String? selectedSubject;

  final List<String> terms = ['Midterm', 'Final'];
  String? selectedTerm;

  bool isLoading = true;
  Map<String, dynamic>? existingMarksData;

  @override
  void initState() {
    super.initState();
    selectedTerm = terms.first;
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    try {
      DocumentSnapshot classDoc =
          await FirebaseFirestore.instance
              .collection('Classes')
              .doc(widget.selectedClass)
              .get();

      List<dynamic> subjectList = classDoc.get('subjects') ?? [];
      subjects = subjectList.cast<String>();

      await loadExistingMarks();

      // Set selectedSubject to first unfilled subject
      final unfilledSubjects =
          subjects.where((s) => !filledSubjects.contains(s)).toList();
      selectedSubject =
          unfilledSubjects.isNotEmpty ? unfilledSubjects.first : null;

      setState(() {
        isLoading = false;
      });

      // Load marks only if selected subject is not already filled
      if (selectedSubject != null &&
          !filledSubjects.contains(selectedSubject)) {
        await loadSubjectMarks(selectedSubject!);
      }
    } catch (e) {
      print("Error fetching subjects: $e");
      setState(() {
        subjects = [];
        isLoading = false;
      });
    }
  }

  Future<void> loadExistingMarks() async {
    if (selectedTerm == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('Classes')
              .doc(widget.selectedClass)
              .collection('Sections')
              .doc(widget.selectedSection)
              .collection('Students')
              .doc(widget.studentId)
              .collection('Results')
              .doc(selectedTerm!)
              .get();

      filledSubjects.clear();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          for (var subject in subjects) {
            if (data.containsKey(subject)) {
              filledSubjects.add(subject);
            }
          }
        }
      }
    } catch (e) {
      print("Error loading existing marks: $e");
    }
  }

  Future<void> loadSubjectMarks(String subject) async {
    if (selectedTerm == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('Classes')
            .doc(widget.selectedClass)
            .collection('Sections')
            .doc(widget.selectedSection)
            .collection('Students')
            .doc(widget.studentId)
            .collection('Results')
            .doc(selectedTerm!)
            .get();

    final data = doc.data();
    if (data != null && data.containsKey(subject)) {
      final subjectData = data[subject];
      _obtainedMarksController.text = subjectData['obtained'].toString();
      _totalMarksController.text = subjectData['total'].toString();
      setState(() {
        existingMarksData = subjectData;
      });
    } else {
      _obtainedMarksController.clear();
      _totalMarksController.clear();
      setState(() {
        existingMarksData = null;
      });
    }
  }

  void clearFieldsAndRefreshSubject() {
    _obtainedMarksController.clear();
    _totalMarksController.clear();
    setState(() {
      existingMarksData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Enter Marks: ${widget.studentName}"),
      content:
          isLoading
              ? const CircularProgressIndicator()
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTerm,
                    items:
                        terms
                            .map(
                              (term) => DropdownMenuItem(
                                value: term,
                                child: Text(term),
                              ),
                            )
                            .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() {
                        selectedTerm = value;
                        isLoading = true;
                      });
                      await fetchSubjects(); // reload subjects + filled data
                    },
                    decoration: const InputDecoration(labelText: "Select Term"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    items:
                        subjects.map((subject) {
                          final isFilled = filledSubjects.contains(subject);
                          return DropdownMenuItem<String>(
                            value: subject, // ✅ Always allow selection
                            child: Text(
                              subject + (isFilled ? " (Already filled)" : ""),
                              style: TextStyle(
                                color:
                                    isFilled ? Color(0xFF1B7FEE) : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() {
                        selectedSubject = value;
                        isLoading = true;
                      });
                      await loadSubjectMarks(
                        value,
                      ); // load existing marks if present
                      setState(() {
                        isLoading = false;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Subject",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _totalMarksController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: "Total Marks"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _obtainedMarksController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Obtained Marks",
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (existingMarksData != null)
                    const Text(
                      "⚠️ Marks already exist. Updating will overwrite.",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Done"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (selectedSubject == null ||
                selectedTerm == null ||
                _obtainedMarksController.text.isEmpty ||
                _totalMarksController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please fill all fields.")),
              );
              return;
            }

            double? obtained = double.tryParse(_obtainedMarksController.text);
            double? total = double.tryParse(_totalMarksController.text);

            if (obtained == null || total == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Enter valid numbers.")),
              );
              return;
            }

            await FirebaseFirestore.instance
                .collection('Classes')
                .doc(widget.selectedClass)
                .collection('Sections')
                .doc(widget.selectedSection)
                .collection('Students')
                .doc(widget.studentId)
                .collection('Results')
                .doc(selectedTerm!)
                .set({
                  selectedSubject!: {'obtained': obtained, 'total': total},
                }, SetOptions(merge: true));

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Marks saved.")));

            clearFieldsAndRefreshSubject();

            // Refresh the whole dialog to disable the filled subject
            await fetchSubjects();
          },
          child: const Text("Save & Continue"),
        ),
      ],
    );
  }
}
