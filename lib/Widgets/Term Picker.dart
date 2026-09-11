// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:workit/Widgets/finalPDF.dart';
import '../services/PDFsee.dart';

class PrintSelectionDialog extends StatelessWidget {
  final String studentName;
  final String studentClass;
  final String studentRollNo;
  final String studentSection; // <-- ADDED
  final Map<String, dynamic> midtermData;
  final Map<String, dynamic> finalData;
  final Map<String, dynamic> combinedData;

  const PrintSelectionDialog({
    super.key,
    required this.studentName,
    required this.studentClass,
    required this.studentRollNo,
    required this.studentSection, // <-- ADDED
    required this.midtermData,
    required this.finalData,
    required this.combinedData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Term to Preview"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTermButton(
            context,
            label: "📘 Midterm PDF",
            term: "Midterm",
            subjectData: midtermData,
          ),
          SizedBox(height: 20),
          _buildTermButton(
            context,
            label: "📗 Final Term PDF",
            term: "Final Term",
            subjectData: finalData,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => FinalReportPdfScreen(
                        midtermData: midtermData,
                        finalData: finalData,
                        studentName: studentName,
                        studentClass: studentClass,
                        rollNo: studentRollNo,
                        studentSection: studentSection, // <-- FIXED HERE
                        showBreakdown: true,
                        combinedData: combinedData,
                      ),
                ),
              );
            },
            child: const Text("📒 Final Report (Combined)"),
          ),
        ],
      ),
    );
  }

  ElevatedButton _buildTermButton(
    BuildContext context, {
    required String label,
    required String term,
    required Map<String, dynamic> subjectData,
  }) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        final dataWithTerm = {
          'term': term,
          'class': studentClass,
          'rollNo': studentRollNo,
          'subjects': subjectData,
        };
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => PdfPreviewScreen(
                  studentName: studentName,
                  resultData: dataWithTerm,
                  studentSection: studentSection,
                ),
          ),
        );
      },
      child: Text(label),
    );
  }
}
