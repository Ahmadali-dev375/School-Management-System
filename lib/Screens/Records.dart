// ignore_for_file: file_names, use_super_parameters, use_build_context_synchronously, non_constant_identifier_names, unnecessary_string_interpolations

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:workit/main.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? _selectedClass;
  String? _selectedSection;
  List<String> _classes = [];
  List<String> _sections = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final snapshot = await firestore.collection('Classes').get();
    setState(() {
      _classes = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _fetchSections(String className) async {
    final snapshot =
        await firestore
            .collection('Classes')
            .doc(className)
            .collection('Sections')
            .get();
    setState(() {
      _sections = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _fetchStudents() async {
    if (_selectedClass == null || _selectedSection == null) return [];
    final snapshot =
        await firestore
            .collection('Classes')
            .doc(_selectedClass)
            .collection('Sections')
            .doc(_selectedSection)
            .collection('Students')
            .get();
    return snapshot.docs;
  }

  void _showDeleteConfirmationDialog(String docId, String name) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text("Are you sure you want to delete $name?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  _deleteStudent(docId);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteStudent(String docId) async {
    await firestore
        .collection('Classes')
        .doc(_selectedClass)
        .collection('Sections')
        .doc(_selectedSection)
        .collection('Students')
        .doc(docId)
        .delete();
    setState(() {}); // Refresh student list
  }

  void _showEditStudentDialog(String docId, Map<String, dynamic> student) {
    final nameController = TextEditingController(text: student['name'] ?? '');
    final rollController = TextEditingController(
      text: student['rollNumber'] ?? '',
    );
    final phoneController = TextEditingController(text: student['phone'] ?? '');
    final fatherNameController = TextEditingController(
      text: student['fatherName'] ?? '',
    );
    final cnicController = TextEditingController(text: student['cnic'] ?? '');
    final genderController = TextEditingController(
      text: student['gender'] ?? '',
    );
    final addressController = TextEditingController(
      text: student['address'] ?? '',
    );
    final sectionController = TextEditingController(
      text: student['section'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Student"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  SizedBox(height: 18),
                  TextField(
                    controller: fatherNameController,
                    decoration: const InputDecoration(labelText: "Father Name"),
                  ),
                  SizedBox(height: 18),
                  TextField(
                    controller: rollController,
                    decoration: const InputDecoration(labelText: "Roll Number"),
                  ),
                  SizedBox(height: 18),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone"),
                  ),
                  SizedBox(height: 18),
                  TextField(
                    controller: cnicController,
                    decoration: const InputDecoration(labelText: "CNIC"),
                  ),
                  SizedBox(height: 18),
                  TextField(
                    controller: genderController,
                    decoration: const InputDecoration(labelText: "Gender"),
                  ),
                  SizedBox(height: 18),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "Address"),
                  ),
                  // TextField(
                  //   controller: sectionController,
                  //   decoration: const InputDecoration(labelText: "Section"),
                  // ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  await firestore
                      .collection('Classes')
                      .doc(_selectedClass)
                      .collection('Sections')
                      .doc(_selectedSection)
                      .collection('Students')
                      .doc(docId)
                      .update({
                        'name': nameController.text.trim(),
                        'rollNumber': rollController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'fatherName': fatherNameController.text.trim(),
                        'cnic': cnicController.text.trim(),
                        'gender': genderController.text.trim(),
                        'address': addressController.text.trim(),
                        'section': sectionController.text.trim(),
                      });
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text("Update"),
              ),
            ],
          ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, String docId) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Name: ${student['name'] ?? ''}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            _buildTeacherField("Father Name", student['fatherName']),
            _buildTeacherField("Roll No", student['rollNumber']),

            _CopybuildTeacherField("Contact", student['phone']),

            _buildTeacherField("Gender", student['Gender']),
            _buildTeacherField("CNIC", student['cnic']),
            _buildTeacherField("Address", student['Address']),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditStudentDialog(docId, student),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black),
                  onPressed:
                      () =>
                          _showDeleteConfirmationDialog(docId, student['name']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Student Records')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: DropdownButtonFormField<String>(
                value: _selectedClass,
                hint: const Text("Select Class"),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items:
                    _classes
                        .map(
                          (className) => DropdownMenuItem(
                            value: className,
                            child: Text(className),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClass = value;
                    _selectedSection = null;
                    _sections = [];
                  });
                  _fetchSections(value!);
                },
              ),
            ),
            if (_selectedClass != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedSection,
                  hint: const Text("Select Section"),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _sections
                          .map(
                            (section) => DropdownMenuItem(
                              value: section,
                              child: Text(section),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => _selectedSection = value),
                ),
              ),
            const SizedBox(height: 8),
            if (_selectedClass == null || _selectedSection == null)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Please select class and section to view students.',
                ),
              )
            else
              Expanded(
                child: FutureBuilder<
                  List<QueryDocumentSnapshot<Map<String, dynamic>>>
                >(
                  future: _fetchStudents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final students = snapshot.data ?? [];
                    if (students.isEmpty) {
                      return const Center(child: Text("No students found."));
                    }
                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index].data();
                        final docId = students[index].id;
                        return _buildStudentCard(student, docId);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTeacherField(String label, String? value) {
  final isMissing = value == null || value.isEmpty || value == 'N/A';

  return Padding(
    padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16), // consistent font size
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              decoration: TextDecoration.underline,
              decorationThickness: 1.2,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const TextSpan(
            text: " :-  ", // This part is NOT underlined
            style: TextStyle(
              decoration: TextDecoration.none,
              color: Colors.black,
            ),
          ),
          TextSpan(
            text: isMissing ? 'N/A' : value,
            style: TextStyle(
              fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
              color: isMissing ? Color(0xFF8A0204) : Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _CopybuildTeacherField(String label, String? value) {
  final isMissing = value == null || value.isEmpty || value == 'N/A';
  final displayText = isMissing ? 'N/A' : value;

  return Padding(
    padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque, // Ensures full area detects touch
      onLongPress: () {
        Clipboard.setData(
          ClipboardData(text: displayText),
        ); // Copies ONLY the value
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.blue,
            content: Text('Copied to clipboard!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$label", // Label is underlined
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    decorationThickness: 1.2,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const TextSpan(
                  text: " :-  ", // This part is NOT underlined
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: displayText,
                  style: TextStyle(
                    fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                    color: isMissing ? const Color(0xFF8A0204) : Colors.blue,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
