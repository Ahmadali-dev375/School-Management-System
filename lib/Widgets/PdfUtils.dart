// ignore_for_file: deprecated_member_use, file_names

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

double calculatePercentage(double obtained, double total) {
  if (total == 0) return 0;
  return (obtained / total) * 100;
}

String getGrade(double percent) {
  if (percent >= 96) return "A+";
  if (percent >= 91) return "A";
  if (percent >= 86) return "A-";
  if (percent >= 81) return "B+";
  if (percent >= 76) return "B";
  if (percent >= 71) return "B-";
  if (percent >= 66) return "C+";
  if (percent >= 61) return "C";
  if (percent >= 56) return "C-";
  if (percent >= 51) return "D+";
  if (percent >= 46) return "D";
  if (percent >= 41) return "D-";
  if (percent >= 31) return "E";
  if (percent >= 21) return "F";
  return "F";
}

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
  final image = pw.MemoryImage(
    (await rootBundle.load('assets/econ.jpg')).buffer.asUint8List(),
  );

  double totalObt = 0;
  double totalMarks = 0;
  final subjectRows = <List<String>>[];

  combinedData.forEach((subject, values) {
    double obtained = (values['obtained'] ?? 0).toDouble();
    double total = (values['total'] ?? 0).toDouble();

    double mid = (midtermData[subject]?['obtained'] ?? 0).toDouble();
    double fin = (finalData[subject]?['obtained'] ?? 0).toDouble();

    if (showBreakdown &&
        (mid + fin).toStringAsFixed(1) != obtained.toStringAsFixed(1)) {
      mid = obtained / 2;
      fin = obtained / 2;
    }

    double percent = calculatePercentage(obtained, total);
    String grade = getGrade(percent);

    totalObt += obtained;
    totalMarks += total;

    subjectRows.add([
      subject,
      total.toStringAsFixed(1),
      if (showBreakdown) mid.toStringAsFixed(1),
      if (showBreakdown) fin.toStringAsFixed(1),
      obtained.toStringAsFixed(1),
      "${percent.toStringAsFixed(1)}%",
      grade,
    ]);
  });

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
            pw.Text("Class: $studentClass", style: pw.TextStyle(fontSize: 14)),
            pw.Text(
              "Section: $studentSection",
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              "Roll No: $studentRollNo",
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Text("Term: Final Report", style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Text(
              "Subject-wise Marks",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: [
                "Subject",
                "Total",
                if (showBreakdown) "Mid",
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
            pw.SizedBox(height: 20),
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
                pw.Text("Principal Signature: ______________"),
                pw.Text("Date: __________"),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
