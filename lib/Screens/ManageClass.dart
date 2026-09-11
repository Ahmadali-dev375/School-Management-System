// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously, use_key_in_widget_constructors, library_private_types_in_public_api, file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditClassSubjectsScreen extends StatefulWidget {
  @override
  _EditClassSubjectsScreenState createState() =>
      _EditClassSubjectsScreenState();
}

class _EditClassSubjectsScreenState extends State<EditClassSubjectsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? _selectedClass;
  List<String> _subjects = [];
  bool _isLoading = false;

  void _loadSubjects() async {
    if (_selectedClass == null) return;
    setState(() => _isLoading = true);

    try {
      final classDoc =
          await firestore.collection('Classes').doc(_selectedClass).get();
      if (classDoc.exists) {
        setState(() {
          _subjects = List<String>.from(classDoc['subjects'] ?? []);
        });
      }
    } catch (e) {
      _showDialog("Error", "Failed to load subjects: $e");
    }

    setState(() => _isLoading = false);
  }

  void _editSubject(int index) {
    TextEditingController controller = TextEditingController(
      text: _subjects[index],
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Edit Subject"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "New Subject Name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String newSubject = controller.text.trim();
                  if (newSubject.isEmpty || _subjects.contains(newSubject))
                    return;

                  setState(() {
                    _subjects[index] = newSubject;
                  });

                  await firestore
                      .collection('Classes')
                      .doc(_selectedClass)
                      .update({'subjects': _subjects});
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  void _removeSubject(int index) async {
    setState(() {
      _subjects.removeAt(index);
    });

    await firestore.collection('Classes').doc(_selectedClass).update({
      'subjects': _subjects,
    });
  }

  void _addNewSubject() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Add New Subject"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Subject Name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String newSubject = controller.text.trim();
                  if (newSubject.isEmpty || _subjects.contains(newSubject))
                    return;

                  setState(() {
                    _subjects.add(newSubject);
                  });

                  await firestore
                      .collection('Classes')
                      .doc(_selectedClass)
                      .update({'subjects': _subjects});
                  Navigator.pop(context);
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  void _deleteClass() async {
    if (_selectedClass == null) return;

    bool confirmDelete = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: Text(
              "Are you sure you want to delete the class '$_selectedClass'? This will remove all sections.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (!confirmDelete) return;

    setState(() => _isLoading = true);

    try {
      final sections =
          await firestore
              .collection('Classes')
              .doc(_selectedClass)
              .collection('Sections')
              .get();
      for (var section in sections.docs) {
        await section.reference.delete();
      }

      await firestore.collection('Classes').doc(_selectedClass).delete();

      _showDialog("Success", "Class deleted successfully.");
      setState(() {
        _selectedClass = null;
        _subjects.clear();
      });
    } catch (e) {
      _showDialog("Error", "Failed to delete class: $e");
    }

    setState(() => _isLoading = false);
  }

  void _renameClass() {
    TextEditingController controller = TextEditingController(
      text: _selectedClass,
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Rename Class"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "New Class Name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String newName = controller.text.trim();
                  if (newName.isEmpty || newName == _selectedClass) return;

                  setState(() => _isLoading = true);
                  Navigator.pop(context);

                  try {
                    final oldClassRef = firestore
                        .collection('Classes')
                        .doc(_selectedClass);
                    final newClassRef = firestore
                        .collection('Classes')
                        .doc(newName);

                    final oldClassData = await oldClassRef.get();
                    if (!oldClassData.exists) throw "Old class not found";

                    // Copy class data (excluding name)
                    await newClassRef.set(oldClassData.data() ?? {});

                    // Copy sections and students
                    final sections =
                        await oldClassRef.collection('Sections').get();
                    for (var section in sections.docs) {
                      final newSectionRef = newClassRef
                          .collection('Sections')
                          .doc(section.id);
                      await newSectionRef.set(section.data());

                      // Copy students in each section
                      final students =
                          await section.reference.collection('Students').get();
                      for (var student in students.docs) {
                        await newSectionRef
                            .collection('Students')
                            .doc(student.id)
                            .set(student.data());
                      }
                    }

                    // Delete old class after copying
                    for (var section in sections.docs) {
                      final students =
                          await section.reference.collection('Students').get();
                      for (var student in students.docs) {
                        await section.reference
                            .collection('Students')
                            .doc(student.id)
                            .delete();
                      }
                      await oldClassRef
                          .collection('Sections')
                          .doc(section.id)
                          .delete();
                    }
                    await oldClassRef.delete();

                    _showDialog("Success", "Class renamed to '$newName'.");

                    setState(() {
                      _selectedClass = newName;
                    });
                  } catch (e) {
                    _showDialog("Error", "Failed to rename class: $e");
                  }

                  setState(() => _isLoading = false);
                },
                child: const Text("Rename"),
              ),
            ],
          ),
    );
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

  void _addNewSection() {
    if (_selectedClass == null) {
      _showDialog("Error", "Please select a class first.");
      return;
    }

    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Add New Section"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Section Name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String newSection = controller.text.trim();
                  if (newSection.isEmpty) return;

                  final sectionRef = FirebaseFirestore.instance
                      .collection('Classes')
                      .doc(_selectedClass)
                      .collection('Sections')
                      .doc(newSection);

                  final sectionDoc = await sectionRef.get();

                  if (sectionDoc.exists) {
                    _showDialog("Error", "Section already exists!");
                    return;
                  }

                  await sectionRef.set({
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  // Close the dialog first
                  Navigator.pop(context);

                  // Show success message after the dialog is closed
                  _showDialog("Success", "Section added successfully.");
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Edit Class Subjects")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('Classes').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();

                  List<DropdownMenuItem<String>> classItems =
                      snapshot.data!.docs.map((doc) {
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(doc.id),
                        );
                      }).toList();

                  return DropdownButton<String>(
                    value: _selectedClass,
                    hint: const Text("Select a Class"),
                    isExpanded: true,
                    items: classItems,
                    onChanged: (value) {
                      setState(() {
                        _selectedClass = value;
                        _subjects.clear();
                      });
                      _loadSubjects();
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
              if (_selectedClass != null)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Add Subject"),
                        onPressed: _addNewSubject,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Add Section"),
                        onPressed: _addNewSection,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("Rename Class"),
                        onPressed: _renameClass,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              if (_isLoading) const CircularProgressIndicator(),

              if (_subjects.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_subjects[index]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editSubject(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeSubject(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              if (_selectedClass != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _deleteClass,
                  child: const Text(
                    "Delete Class",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
