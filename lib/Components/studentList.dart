// ignore_for_file: use_super_parameters, file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MarksDialog.dart'; // This should contain EnterMarksDialog

class StudentList extends StatelessWidget {
  final String? selectedClass;
  final String? selectedSection;
  final String teacherCnic;
  final bool canEnterMarks;

  const StudentList({
    Key? key,
    required this.selectedClass,
    required this.selectedSection,
    required this.teacherCnic,
    required this.canEnterMarks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedClass == null || selectedSection == null) {
      return const Center(child: Text("Select Class & Section"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Classes')
              .doc(selectedClass)
              .collection('Sections')
              .doc(selectedSection)
              .collection('Students')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No students found."));
        }

        var studentDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: studentDocs.length,
          itemBuilder: (context, index) {
            var student = studentDocs[index].data() as Map<String, dynamic>;
            String studentId = studentDocs[index].id;
            String studentName = student['name'] ?? 'Unknown';

            return Card(
              child: ListTile(
                title: Text(studentName),
                subtitle: Text("Student ID: $studentId"),
                trailing:
                    canEnterMarks
                        ? ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => EnterMarksDialog(
                                    studentId: studentId,
                                    studentName: studentName,
                                    selectedClass: selectedClass!,
                                    selectedSection:
                                        selectedSection ?? 'General',
                                  ),
                            );
                          },
                          child: const Text("Enter Marks"),
                        )
                        : const Text("No Permission"),
              ),
            );
          },
        );
      },
    );
  }
}
