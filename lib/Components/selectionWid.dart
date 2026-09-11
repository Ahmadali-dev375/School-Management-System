// ignore_for_file: file_names, use_super_parameters

import 'package:flutter/material.dart';

class ClassSectionSelector extends StatelessWidget {
  final List<String> classes;
  final List<String> sections;
  final String? selectedClass;
  final String? selectedSection;
  final Function(String?) onClassChanged;
  final Function(String?) onSectionChanged;
  final bool isLoadingClasses;
  final bool isLoadingSections;

  const ClassSectionSelector({
    Key? key,
    required this.classes,
    required this.sections,
    required this.selectedClass,
    required this.selectedSection,
    required this.onClassChanged,
    required this.onSectionChanged,
    required this.isLoadingClasses,
    required this.isLoadingSections,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        isLoadingClasses
            ? const CircularProgressIndicator()
            : DropdownButtonFormField<String>(
              value: selectedClass,
              isExpanded: true, // ✅ Required for proper dropdown behavior
              decoration: const InputDecoration(
                labelText: 'Select Class',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items:
                  classes
                      .map(
                        (className) => DropdownMenuItem(
                          value: className,
                          child: Text(className),
                        ),
                      )
                      .toList(),
              onChanged: onClassChanged,
            ),
        const SizedBox(height: 12),
        isLoadingSections
            ? const CircularProgressIndicator()
            : DropdownButtonFormField<String>(
              value: selectedSection,
              isExpanded: true, // ✅ Important for wide dropdown
              decoration: const InputDecoration(
                labelText: 'Select Section',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items:
                  sections
                      .map(
                        (sectionName) => DropdownMenuItem(
                          value: sectionName,
                          child: Text("Section $sectionName"),
                        ),
                      )
                      .toList(),
              onChanged: onSectionChanged,
            ),
      ],
    );
  }
}
