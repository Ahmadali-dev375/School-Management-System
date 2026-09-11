// ignore_for_file: use_super_parameters, file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:workit/Widgets/NewResultCard.dart';
import '../Widgets/PdfUtils.dart';
import '../Widgets/ResultCard.dart';
import '../Widgets/Term Picker.dart';

class StudentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final String studentClass;

  const StudentDetailScreen({
    Key? key,
    required this.studentData,
    required this.studentClass,
  }) : super(key: key);

  // ✅ Calculate percentage for each subject
  double calculateSubjectPercentage(int obtained, int total) {
    if (total == 0) return 0;
    return (obtained / total) * 100;
  }

  // ✅ Step 1: Get grade based on new lenient scale
  String getGrade(double percentage) {
    if (percentage >= 96) return "A+";
    if (percentage >= 91) return "A";
    if (percentage >= 86) return "A-";
    if (percentage >= 81) return "B+";
    if (percentage >= 76) return "B";
    if (percentage >= 71) return "B-";
    if (percentage >= 66) return "C+";
    if (percentage >= 61) return "C";
    if (percentage >= 56) return "C-";
    if (percentage >= 51) return "D+";
    if (percentage >= 46) return "D";
    if (percentage >= 41) return "D-";
    if (percentage >= 31) return "E";
    if (percentage >= 21) return "F";
    return "F";
  }

  // ✅ Step 2: Use it in your calculation
  String calculateGrade(double obtained, double total) {
    if (total == 0) return "F";
    double percentage = (obtained / total) * 100;
    return getGrade(percentage);
  }

  @override
  Widget build(BuildContext context) {
    String section = studentData['section'] ?? 'General';
    String studentId = studentData['id'];

    CollectionReference resultsRef = FirebaseFirestore.instance
        .collection('Classes')
        .doc(studentClass)
        .collection('Sections')
        .doc(section)
        .collection('Students')
        .doc(studentId)
        .collection('Results');

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(studentData['name'] ?? 'Student Details')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: resultsRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No results found."));
              }

              final results = snapshot.data!.docs;

              // 🔁 Convert term docs to map
              Map<String, dynamic> allTermsData = {};

              for (var termDoc in results) {
                String term = termDoc.id;
                Map<String, dynamic> termData =
                    termDoc.data() as Map<String, dynamic>;
                allTermsData[term] = termData;
              }

              return ListView(
                children: [
                  // ✅ Student Bio Section
                  Card(
                    //  color: Colors.blue,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "📄 Student Bio",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text("👤 Name: ${studentData['name']}"),
                          if (studentData['fatherName'] != null)
                            Text(
                              "👨‍👧 Father Name: ${studentData['fatherName']}",
                            ),
                          Text("🆔 Roll No: ${studentData['rollNumber']}"),
                          Text("🏫 Class: $studentClass"),
                          Text("🏷️ Section: $section"),
                          // if (studentData['cnic'] != null)
                          //   Text("🪪 CNIC: ${studentData['cnic']}"),
                        ],
                      ),
                    ),
                  ),
                  // ✅ New Results UI
                  buildTermResults(
                    context,
                    allTermsData,
                    studentData['name'],
                    studentClass,
                    section,
                    studentData['rollNumber'],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 📘 Builds the Term Results + Final Report Card
  Widget buildTermResults(
    BuildContext context,
    Map<String, dynamic> allTermsData,
    String studentName,
    String studentClass,
    String studentSection,
    String studentRollNo,
  ) {
    // Map<String, dynamic> midData = allTermsData['Midterm'] ?? {};
    // Map<String, dynamic> finalData = allTermsData['Final Term'] ?? {};
    Map<String, dynamic> midData = {};
    Map<String, dynamic> finalData = {};

    allTermsData.forEach((termKey, termValue) {
      if (termKey.toLowerCase().contains('mid')) {
        midData = termValue;
      } else if (termKey.toLowerCase().contains('final')) {
        finalData = termValue;
      }
    });

    Map<String, dynamic> combinedData = {};

    // 🔁 Combine per subject
    Set<String> allSubjects = {...midData.keys, ...finalData.keys};

    for (var subject in allSubjects) {
      double midObt = (midData[subject]?['obtained'] ?? 0).toDouble();
      double midTotal = (midData[subject]?['total'] ?? 0).toDouble();
      double finalObt = (finalData[subject]?['obtained'] ?? 0).toDouble();
      double finalTotal = (finalData[subject]?['total'] ?? 0).toDouble();

      combinedData[subject] = {
        'obtained': midObt + finalObt,
        'total': midTotal + finalTotal,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResultCard(term: "📘 Midterm", data: midData),
        ResultCard(term: "📗 Final Term", data: finalData),
        const Divider(thickness: 2),
        // ResultCard(term: "📒 Final Report (Mid + Final)", data: combinedData),
        FinalResultCard(
          term: "Final Report",
          data: combinedData,
          midtermData: midData, // Map<String, Map<String, dynamic>>
          finalData: finalData, // Same structure
          showBreakdown: true, // Trigger breakdown format
        ),

        const Divider(thickness: 1),

        //   buildOverallSummaryCard(combinedData),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Export as PDF"),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (ctx) => PrintSelectionDialog(
                      studentSection: studentSection,
                      studentName: studentName,
                      studentClass: studentClass,
                      studentRollNo: studentRollNo,
                      midtermData: midData,
                      finalData: finalData,
                      combinedData: combinedData,
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget buildOverallSummaryCard(Map<String, dynamic> combinedData) {
  double totalObt = 0;
  double totalMarks = 0;

  combinedData.forEach((subject, marks) {
    totalObt += (marks['obtained'] ?? 0).toDouble();
    totalMarks += (marks['total'] ?? 0).toDouble();
  });

  double percentage = totalMarks == 0 ? 0 : (totalObt / totalMarks) * 100;
  String grade = getGrade(percentage);
  bool isPassed = !(grade == "F" || grade == "F");

  return Card(
    color: Colors.grey[200],
    margin: const EdgeInsets.symmetric(vertical: 12),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📋 Final Progress Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text("📌 Total Obtained Marks: $totalObt"),
          Text("🧮 Total Marks: $totalMarks"),
          Text("📊 Overall Percentage: ${percentage.toStringAsFixed(2)}%"),
          Text("🏆 Final Grade: $grade"),
          Text(
            isPassed ? "✅ Status: Passed" : "❌ Status: Failed",
            style: TextStyle(
              color: isPassed ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

////updated
