// ignore_for_file: file_names, unnecessary_this, deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;
  final String studentName;
  final String studentSection;

  const PdfPreviewScreen({
    super.key,
    required this.resultData,
    required this.studentName,
    required this.studentSection,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("PDF Preview")),
        body: PdfPreview(
          build: (format) => generatePdf(resultData, studentName),
        ),
      ),
    );
  }

  // Percentage calculator
  double calculatePercentage(double obtained, double total) =>
      total == 0 ? 0 : (obtained / total) * 100;

  // Updated grading system
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

  Future<Uint8List> generatePdf(
    Map<String, dynamic> data,
    String studentName,
  ) async {
    final pdf = pw.Document();

    final term = data['term'] ?? 'N/A';
    final studentClass = data['class'] ?? 'N/A';
    final section = this.studentSection; // ✅ Use the constructor value
    final rollNo = data['rollNo'] ?? 'N/A';
    final subjects = data['subjects'] ?? {};

    double totalObtained = 0;
    double totalMarks = 0;

    final tableData = <List<String>>[];

    // Sort subjects alphabetically
    List<String> sortedSubjects = subjects.keys.toList()..sort();

    for (var subject in sortedSubjects) {
      var marks = subjects[subject];

      if (marks is Map<String, dynamic>) {
        final obtained = (marks['obtained'] ?? 0).toDouble();
        final total = (marks['total'] ?? 0).toDouble();

        final percent = calculatePercentage(obtained, total);
        final grade = getGrade(percent);

        totalObtained += obtained;
        totalMarks += total;

        tableData.add([
          subject, // Left-aligned
          total.toStringAsFixed(0), // Right-aligned
          obtained.toStringAsFixed(0), // Right-aligned
          "${percent.toStringAsFixed(1)}%", // Right-aligned
          grade, // Center-aligned
        ]);
      }
    }

    final overallPercentage =
        totalMarks > 0 ? (totalObtained / totalMarks) * 100 : 0;
    final overallGrade = getGrade(overallPercentage.toDouble());

    final status = overallPercentage >= 31 ? "Passed" : "Failed";

    final image = await imageFromAssetBundle('assets/econ.jpg');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Image(image, height: 80)),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  "Noble School System and College Chak 41 GB, Samundari",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Name: $studentName", style: pw.TextStyle(fontSize: 14)),
              pw.Text("Roll No: $rollNo", style: pw.TextStyle(fontSize: 14)),
              pw.Text(
                "Class: $studentClass",
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text("Section: $section", style: pw.TextStyle(fontSize: 14)),
              pw.Text("Term: $term", style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),

              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Subject', 'Obtained', 'Total', '%', 'Grade'],
                data: tableData,
                border: pw.TableBorder.all(color: PdfColors.grey),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                },
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                "Total Marks: ${totalObtained.toInt()} / ${totalMarks.toInt()}",
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                "Overall Percentage: ${overallPercentage.toStringAsFixed(2)}%",
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                "Overall Grade: $overallGrade",
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                "Status: $status",
                style: pw.TextStyle(
                  fontSize: 14,
                  color: status == "Passed" ? PdfColors.green : PdfColors.red,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Teacher Signature: ______________"),
                  pw.Text("Recieved by: __________"),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
