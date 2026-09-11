// ignore_for_file: deprecated_member_use, file_names

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FinalReportPdfScreen extends StatelessWidget {
  final Map<String, dynamic> combinedData;
  final Map<String, dynamic>? midtermData;
  final Map<String, dynamic>? finalData;
  final String studentName;
  final String studentClass;
  final String studentSection;
  final String rollNo;
  final bool showBreakdown;

  const FinalReportPdfScreen({
    super.key,
    required this.combinedData,
    required this.midtermData,
    required this.finalData,
    required this.studentName,
    required this.studentClass,
    required this.studentSection,
    required this.rollNo,
    this.showBreakdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Final Report PDF Preview")),
        body: FutureBuilder<Uint8List>(
          future: generateCombinedPdf(
            studentName: studentName,
            studentClass: studentClass,
            studentSection: studentSection,
            studentRollNo: rollNo,
            midtermData: midtermData ?? {},
            finalData: finalData ?? {},
            combinedData: combinedData,
            showBreakdown: showBreakdown,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return PdfPreview(build: (format) => snapshot.data!);
          },
        ),
      ),
    );
  }

  // Grade calculation helper
  double calculatePercentage(double obtained, double total) =>
      total == 0 ? 0 : (obtained / total) * 100;

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

  // PDF generator function
  Future<Uint8List> generateCombinedPdf({
    required String studentName,
    required String studentClass,
    required String studentSection,
    required String studentRollNo,
    required Map<String, dynamic> midtermData,
    required Map<String, dynamic> finalData,
    required Map<String, dynamic> combinedData,
    required bool showBreakdown,
  }) async {
    final pdf = pw.Document();
    final image = await imageFromAssetBundle('assets/econ.jpg');
    double totalObt = 0;
    double totalMarks = 0;
    final subjectRows = <List<String>>[];

    // Sort subjects alphabetically
    List<String> sortedSubjects = combinedData.keys.toList()..sort();

    for (var subject in sortedSubjects) {
      var values = combinedData[subject]!;
      double obtained = (values['obtained'] ?? 0).toDouble();
      double total = (values['total'] ?? 0).toDouble();
      double mid = (midtermData[subject]?['obtained'] ?? 0).toDouble();
      double fin = (finalData[subject]?['obtained'] ?? 0).toDouble();

      if (showBreakdown &&
          (mid + fin).toStringAsFixed(1) != obtained.toStringAsFixed(1)) {
        mid = obtained / 2;
        fin = obtained / 2;
      }

      // **Update total obtained and total marks**
      totalObt += obtained;
      totalMarks += total;

      double percent = calculatePercentage(obtained, total);
      String grade = getGrade(percent);

      subjectRows.add([
        subject,
        total.toStringAsFixed(1),
        mid.toStringAsFixed(1),
        fin.toStringAsFixed(1),
        obtained.toStringAsFixed(1),
        "${percent.toStringAsFixed(1)}%",
        grade,
      ]);
    }

    // Calculate overall percentage and grade
    final overallPercentage = calculatePercentage(totalObt, totalMarks);
    final overallGrade = getGrade(overallPercentage);
    final status = overallPercentage >= 31 ? "Passed" : "Failed";

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
                  "Noble School System and College\nChak 41 GB, Samundari",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Name: $studentName", style: pw.TextStyle(fontSize: 14)),
              pw.Text(
                "Roll No: $studentRollNo",
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                "Class: $studentClass",
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                "Section: $studentSection",
                style: pw.TextStyle(fontSize: 14),
              ),
              // pw.Text("Term: Final Report", style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              // pw.Text(
              //   "Subject-wise Marks",
              //   style: pw.TextStyle(
              //     fontSize: 16,
              //     fontWeight: pw.FontWeight.bold,
              //   ),
              // ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: [
                  "Subject",
                  "Total",
                  if (showBreakdown) "Mids",
                  if (showBreakdown) "Final",
                  "Obt.",
                  "%",
                  "Grade",
                ],
                data: subjectRows,
                border: pw.TableBorder.all(color: PdfColors.grey),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.center,
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                "Total: ${totalObt.toStringAsFixed(1)} / ${totalMarks.toStringAsFixed(1)}",
              ),
              pw.Text(
                "Overall Percentage: ${overallPercentage.toStringAsFixed(2)}%",
              ),
              pw.Text("Overall Grade: $overallGrade"),
              pw.Text(
                "Status: $status",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: status == "Passed" ? PdfColors.green : PdfColors.red,
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
