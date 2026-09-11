// ignore_for_file: use_super_parameters, file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddClassWithSubjectsScreen extends StatefulWidget {
  const AddClassWithSubjectsScreen({Key? key}) : super(key: key);

  @override
  State<AddClassWithSubjectsScreen> createState() =>
      _AddClassWithSubjectsScreenState();
}

class _AddClassWithSubjectsScreenState
    extends State<AddClassWithSubjectsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController _classController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  final List<String> _subjects = [];
  final List<String> _sections = [];

  bool _isLoading = false;

  void _addSubject() {
    final subject = _subjectController.text.trim();
    if (subject.isNotEmpty && !_subjects.contains(subject)) {
      setState(() {
        _subjects.add(subject);
        _subjectController.clear();
      });
    }
  }

  void _addSection() {
    final section = _sectionController.text.trim();
    if (section.isNotEmpty && !_sections.contains(section)) {
      setState(() {
        _sections.add(section);
        _sectionController.clear();
      });
    }
  }

  Future<void> _createClassWithSubjects() async {
    final className = _classController.text.trim();
    if (className.isEmpty || _subjects.isEmpty) {
      _showDialog(
        "Validation Error",
        "Class name and at least one subject are required.",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final classRef = firestore.collection('Classes').doc(className);
      final classSnapshot = await classRef.get();

      // ✅ Check if class already exists
      if (classSnapshot.exists) {
        _showDialog(
          "Class Exists",
          "The class '$className' already exists. Please choose a different name or modify subjects manually.",
        );
        setState(() => _isLoading = false);
        return;
      }

      // Save class and subjects
      await classRef.set({'subjects': _subjects});

      // Save sections (if any)
      if (_sections.isNotEmpty) {
        for (final section in _sections) {
          await classRef.collection('Sections').doc(section).set({});
        }
      }

      _showDialog(
        "Success",
        "Class '$className' created with subjects${_sections.isNotEmpty ? ' and sections' : ''}.",
      );

      // Clear input fields
      _classController.clear();
      _subjectController.clear();
      _sectionController.clear();
      _subjects.clear();
      _sections.clear();
    } catch (e) {
      _showDialog("Error", "Failed to create class: $e");
    }

    setState(() => _isLoading = false);
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Add Class with Subjects")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _classController,
                decoration: const InputDecoration(
                  labelText: "Class Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Subject Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: "Add Subject",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSubject,
                    child: const Text("+ Add"),
                  ),
                ],
              ),

              if (_subjects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      _subjects
                          .map((subject) => Chip(label: Text(subject)))
                          .toList(),
                ),
              ],
              const SizedBox(height: 24),

              // Section Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sectionController,
                      decoration: const InputDecoration(
                        labelText: "Add Section (Optional)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSection,
                    child: const Text("+ Add"),
                  ),
                ],
              ),

              if (_sections.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      _sections
                          .map(
                            (section) => Chip(label: Text("Section $section")),
                          )
                          .toList(),
                ),
              ],
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _createClassWithSubjects,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Create Class"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
