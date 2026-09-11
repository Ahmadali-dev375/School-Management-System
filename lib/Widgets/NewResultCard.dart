// ignore_for_file: file_names, avoid_function_literals_in_foreach_calls

import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final String term;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? midtermData;
  final Map<String, dynamic>? finalData;
  final bool showBreakdown;

  const ResultCard({
    super.key,
    required this.term,
    required this.data,
    this.midtermData,
    this.finalData,
    this.showBreakdown = false,
  });

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

  @override
  Widget build(BuildContext context) {
    double totalObt = 0;
    double totalMarks = 0;

    List<TableRow> subjectRows = [];
    List<String> sortedSubjects = data.keys.toList()..sort();

    sortedSubjects.forEach((subject) {
      var values = data[subject];
      double obtained = (values['obtained'] ?? 0).toDouble();
      double total = (values['total'] ?? 0).toDouble();

      double mid = (midtermData?[subject]?['obtained'] ?? 0).toDouble();
      double fin = (finalData?[subject]?['obtained'] ?? 0).toDouble();

      // Fall back to equal split if data missing
      if (showBreakdown && (mid + fin) != obtained) {
        mid = obtained / 2;
        fin = obtained / 2;
      }
      double percent = calculatePercentage(obtained, total);
      String grade = getGrade(percent);

      totalObt += obtained;
      totalMarks += total;

      subjectRows.add(
        TableRow(
          children: [
            tableCell(subject),
            tableCell(total.toStringAsFixed(1)),
            if (showBreakdown) tableCell(mid.toStringAsFixed(1)),
            if (showBreakdown) tableCell(fin.toStringAsFixed(1)),
            tableCell(obtained.toStringAsFixed(1)),

            tableCell("${percent.toStringAsFixed(1)}%"),
            tableCell(grade),
          ],
        ),
      );
    });

    double overallPercent = calculatePercentage(totalObt, totalMarks);
    String finalGrade = getGrade(overallPercent);
    bool isPassed = finalGrade != "F";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📘 Term: $term",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(color: Colors.grey),
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(2),
                5: FlexColumnWidth(2),
                6: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Colors.blue),
                  children: [
                    tableHeader("Subject"),
                    tableHeader("Total"),
                    if (showBreakdown) tableHeader("Mid"),
                    if (showBreakdown) tableHeader("Final"),
                    tableHeader("Obt."),
                    tableHeader("%"),
                    tableHeader("Grade"),
                  ],
                ),
                ...subjectRows,
              ],
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1.5),
            Text("📌 Total Obtained: ${totalObt.toStringAsFixed(2)}"),
            Text("🧮 Total Marks: ${totalMarks.toStringAsFixed(2)}"),
            Text("📊 Percentage: ${overallPercent.toStringAsFixed(2)}%"),
            Text("🏆 Final Grade: $finalGrade"),
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

  Widget tableHeader(String text) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    ),
  );

  Widget tableCell(String text) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
    ),
  );
}
/// New updated