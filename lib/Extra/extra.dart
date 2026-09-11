// ignore_for_file: use_super_parameters, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMarks extends StatefulWidget {
  const AddMarks({Key? key}) : super(key: key);

  @override
  State<AddMarks> createState() => _AddMarksState();
}

class _AddMarksState extends State<AddMarks> {
  String? _selectedClass;
  String? _selectedSection;
  List<String> _classes = [];
  List<String> _sections = [];

  bool _isLoadingClasses = false;
  bool _isLoadingSections = false;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      QuerySnapshot classSnapshot =
          await FirebaseFirestore.instance.collection('Classes').get();
      setState(() {
        _classes = classSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print("Error fetching classes: $e");
    }
    setState(() => _isLoadingClasses = false);
  }

  Future<void> _fetchSections(String className) async {
    setState(() {
      _isLoadingSections = true;
      _sections = [];
      _selectedSection = null;
    });

    try {
      QuerySnapshot sectionSnapshot =
          await FirebaseFirestore.instance
              .collection('Classes')
              .doc(className)
              .collection('Sections')
              .get();

      setState(() {
        _sections = sectionSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print("Error fetching sections: $e");
    }
    setState(() => _isLoadingSections = false);
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
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Marks for $studentName"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: InputDecoration(labelText: "Subject Name"),
              ),
              TextField(
                controller: obtainedMarksController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Obtained Marks"),
              ),
              TextField(
                controller: totalMarksController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Total Marks"),
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
                String obtainedMarks = obtainedMarksController.text.trim();
                String totalMarks = totalMarksController.text.trim();

                if (subject.isNotEmpty &&
                    obtainedMarks.isNotEmpty &&
                    totalMarks.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('Classes')
                      .doc(_selectedClass)
                      .collection('Sections')
                      .doc(_selectedSection)
                      .collection('Students')
                      .doc(studentId)
                      .set({
                        'marks': {
                          subject: {
                            'obtained': int.tryParse(obtainedMarks) ?? 0,
                            'total': int.tryParse(totalMarks) ?? 100,
                          },
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
        );
      },
    );
  }

  //*********************************
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Marks'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _isLoadingClasses
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Select Class',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _classes.map((className) {
                        return DropdownMenuItem(
                          value: className,
                          child: Text(className),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                      _selectedSection = null;
                    });
                    _fetchSections(value!);
                  },
                ),
            const SizedBox(height: 10),

            _isLoadingSections
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: const InputDecoration(
                    labelText: 'Select Section',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _sections.map((sectionName) {
                        return DropdownMenuItem(
                          value: sectionName,
                          child: Text("Section $sectionName"),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSection = value;
                    });
                  },
                ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    (_selectedClass != null && _selectedSection != null)
                        ? FirebaseFirestore.instance
                            .collection('Classes')
                            .doc(_selectedClass)
                            .collection('Sections')
                            .doc(_selectedSection)
                            .collection('Students')
                            .snapshots()
                        : null,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: Text("Select Class & Section"));
                  }

                  var students = snapshot.data!.docs.toList();

                  return students.isEmpty
                      ? const Center(child: Text("No students found."))
                      : ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          var student = students[index];
                          String studentId = student.id;
                          String studentName = student['name'];

                          return Card(
                            child: ListTile(
                              title: Text(studentName),
                              subtitle: Text(
                                "Roll Number: ${student['rollNumber']}",
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  _showMarkEntryDialog(studentId, studentName);
                                },
                                child: const Text("Enter Marks"),
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
      ),
    );
  }
}
// Add Marks