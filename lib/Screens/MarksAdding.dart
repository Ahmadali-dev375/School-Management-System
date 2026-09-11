// AddMarksScreen.dart
// ignore_for_file: use_super_parameters, use_build_context_synchronously, avoid_print, file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Components/selectionWid.dart';
import '../Components/studentList.dart';

class AddMarksScreen extends StatefulWidget {
  final String teacherCnic;
  const AddMarksScreen({Key? key, required this.teacherCnic}) : super(key: key);

  @override
  State<AddMarksScreen> createState() => _AddMarksScreenState();
}

class _AddMarksScreenState extends State<AddMarksScreen> {
  String? _selectedClass;
  String? _selectedSection;
  List<String> _availableClasses = [];
  Map<String, List<String>> _classSectionMap = {};
  bool _isLoading = false;

  // ✅ Add this helper method here
  String _normalizeCnic(String cnic) {
    return cnic.trim(); // Don't remove dashes
  }

  @override
  void initState() {
    super.initState();
    _loadTeacherClasses();
  }

  Future<void> _loadTeacherClasses() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Use normalized CNIC for document ID
      String teacherDocId = "Teacher${_normalizeCnic(widget.teacherCnic)}";

      print("📌 CNIC passed to screen: ${widget.teacherCnic}");
      print("📄 Fetching document: Teacher${widget.teacherCnic.trim()}");

      final doc =
          await FirebaseFirestore.instance
              .collection('Teachers')
              .doc(teacherDocId)
              .get();

      if (doc.exists) {
        final data = doc.data();
        final assigned = data?['assignedClasses'] ?? [];

        Map<String, List<String>> tempMap = {};
        for (var entry in assigned) {
          final className = entry['class'];
          final sectionName = entry['section'];

          if (!tempMap.containsKey(className)) {
            tempMap[className] = [];
          }
          if (!tempMap[className]!.contains(sectionName)) {
            tempMap[className]!.add(sectionName);
          }
        }

        setState(() {
          _classSectionMap = tempMap;
          _availableClasses = tempMap.keys.toList();

          if (_availableClasses.isNotEmpty) {
            _selectedClass = _availableClasses.first;
            _selectedSection = tempMap[_selectedClass!]!.first;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Teacher document not found.")),
        );
      }
    } catch (e) {
      print("❌ Error loading: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error loading class data.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Marks'), centerTitle: true),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Select Class & Section",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClassSectionSelector(
                            classes: _availableClasses,
                            sections:
                                _selectedClass != null
                                    ? _classSectionMap[_selectedClass] ?? []
                                    : [],
                            selectedClass: _selectedClass,
                            selectedSection: _selectedSection,
                            onClassChanged: (value) {
                              setState(() {
                                _selectedClass = value;
                                final sections = _classSectionMap[value] ?? [];
                                _selectedSection =
                                    sections.isNotEmpty ? sections.first : null;
                              });
                            },
                            onSectionChanged:
                                (value) =>
                                    setState(() => _selectedSection = value),
                            isLoadingClasses: false,
                            isLoadingSections: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_selectedClass != null && _selectedSection != null)
                        SizedBox(
                          height: 900,
                          child: StudentList(
                            selectedClass: _selectedClass!,
                            selectedSection: _selectedSection!,
                            teacherCnic: widget.teacherCnic,
                            canEnterMarks: true,
                          ),
                        )
                      else
                        const Text("Please select class and section."),
                    ],
                  ),
                ),
      ),
    );
  }
}
