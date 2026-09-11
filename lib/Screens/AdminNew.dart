// ignore_for_file: unused_element, file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ClassWisePermissionManager extends StatefulWidget {
  final String? preselectedClass; // Optional initial class selection

  const ClassWisePermissionManager({super.key, this.preselectedClass});

  @override
  State<ClassWisePermissionManager> createState() =>
      _ClassWisePermissionManagerState();
}

class _ClassWisePermissionManagerState
    extends State<ClassWisePermissionManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedClass;
  Map<String, List<String>> _classSections = {};
  List<Map<String, dynamic>> _teachersWithThisClass = [];

  @override
  void initState() {
    super.initState();
    _fetchAllClassSectionData();
  }

  void _fetchAllClassSectionData() async {
    final classesSnapshot = await _firestore.collection('Classes').get();

    Map<String, List<String>> result = {};
    for (var classDoc in classesSnapshot.docs) {
      final sectionsSnapshot =
          await _firestore
              .collection('Classes')
              .doc(classDoc.id)
              .collection('Sections')
              .get();

      List<String> sections =
          sectionsSnapshot.docs.map((doc) => doc.id).toList();
      sections.add('General'); // Ensure 'General' is always an option
      result[classDoc.id] = sections;
    }

    setState(() {
      _classSections = result;
      if (widget.preselectedClass != null) {
        _selectedClass = widget.preselectedClass;
        _fetchTeachersForSelectedClass(_selectedClass!);
      }
    });
  }

  Future<void> _fetchTeachersForSelectedClass(String selectedClass) async {
    final snapshot = await _firestore.collection('Teachers').get();
    List<Map<String, dynamic>> filtered = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final assigned = List<Map<String, dynamic>>.from(
        data['assignedClasses'] ?? [],
      );
      final filteredAssignments =
          assigned.where((pair) => pair['class'] == selectedClass).toList();

      if (filteredAssignments.isNotEmpty) {
        filtered.add({
          'teacherId': doc.id,
          'name': data['name'],
          'cnic': data['cnic'],
          'assigned': assigned,
          'filteredAssignments': filteredAssignments,
        });
      }
    }

    setState(() {
      _teachersWithThisClass = filtered;
    });
  }

  Future<void> _removeClassSectionFromTeacher(
    String teacherId,
    String className,
    String sectionName,
  ) async {
    final docRef = _firestore.collection('Teachers').doc(teacherId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    List<dynamic> assigned = doc.data()!['assignedClasses'] ?? [];
    assigned.removeWhere(
      (entry) => entry['class'] == className && entry['section'] == sectionName,
    );

    await docRef.update({'assignedClasses': assigned});
    Fluttertoast.showToast(msg: "Removed $className - $sectionName");

    _fetchTeachersForSelectedClass(className);
  }

  Future<void> _addSectionToTeacher(
    String teacherId,
    String className,
    String sectionName,
  ) async {
    final docRef = _firestore.collection('Teachers').doc(teacherId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    List<dynamic> assigned = List.from(doc.data()!['assignedClasses'] ?? []);
    bool alreadyExists = assigned.any(
      (entry) => entry['class'] == className && entry['section'] == sectionName,
    );

    if (!alreadyExists) {
      assigned.add({'class': className, 'section': sectionName});
      await docRef.update({'assignedClasses': assigned});
      Fluttertoast.showToast(msg: "Added $className - $sectionName");
      _fetchTeachersForSelectedClass(className);
    } else {
      Fluttertoast.showToast(
        msg: "Already assigned",
        backgroundColor: Colors.orange,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500,
        height: 600,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                "Manage Class-Wise Permissions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              /// Class Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Select Class",
                  border: OutlineInputBorder(),
                ),
                value: _selectedClass,
                items:
                    _classSections.keys
                        .map(
                          (cls) =>
                              DropdownMenuItem(value: cls, child: Text(cls)),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedClass = value;
                    _teachersWithThisClass.clear();
                  });
                  _fetchTeachersForSelectedClass(value);
                },
              ),

              const SizedBox(height: 20),

              /// Teachers List
              Expanded(
                child:
                    _teachersWithThisClass.isEmpty
                        ? const Center(child: Text("⏳ Please wait a moment..."))
                        : ListView.separated(
                          itemCount: _teachersWithThisClass.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final teacher = _teachersWithThisClass[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              title: Text(
                                "${teacher['name']} (${teacher['cnic']})",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Assigned Sections:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: List.generate(
                                      teacher['filteredAssignments'].length,
                                      (i) {
                                        final entry =
                                            teacher['filteredAssignments'][i];
                                        return Chip(
                                          label: Text(entry['section']),
                                          onDeleted: () {
                                            _removeClassSectionFromTeacher(
                                              teacher['teacherId'],
                                              _selectedClass!,
                                              entry['section'],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  // const SizedBox(height: 10),
                                  // Align(
                                  //   alignment: Alignment.centerLeft,
                                  //   child: TextButton.icon(
                                  //     icon: const Icon(Icons.add),
                                  //     label: const Text("Add Section"),
                                  //     onPressed: () {
                                  //       showDialog(
                                  //         context: context,
                                  //         builder: (_) {
                                  //           final sections =
                                  //               _classSections[_selectedClass]!;
                                  //           return AlertDialog(
                                  //             title: const Text(
                                  //               "Select Section",
                                  //             ),
                                  //             content: SizedBox(
                                  //               width: double.maxFinite,
                                  //               child: ListView.builder(
                                  //                 shrinkWrap: true,
                                  //                 itemCount: sections.length,
                                  //                 itemBuilder: (context, idx) {
                                  //                   final section =
                                  //                       sections[idx];
                                  //                   return ListTile(
                                  //                     title: Text(section),
                                  //                     onTap: () {
                                  //                       Navigator.pop(context);
                                  //                       _addSectionToTeacher(
                                  //                         teacher['teacherId'],
                                  //                         _selectedClass!,
                                  //                         section,
                                  //                       );
                                  //                     },
                                  //                   );
                                  //                 },
                                  //               ),
                                  //             ),
                                  //           );
                                  //         },
                                  //       );
                                  //     },
                                  //   ),
                                  // ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
