// ignore_for_file: use_super_parameters, use_build_context_synchronously, curly_braces_in_flow_control_structures, file_names, non_constant_identifier_names, unnecessary_string_interpolations

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:workit/main.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({Key? key}) : super(key: key);

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _fetchTeachers() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await firestore.collection('Teachers').get();
    return snapshot.docs;
  }

  void _showEditTeacherDialog(
    String docId,
    String name,
    String subject,
    String contact,
    String email,
    String gender,
    String cnic,
    String father,
    String address,
  ) {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController subjectController = TextEditingController(
      text: subject,
    );
    TextEditingController contactController = TextEditingController(
      text: contact,
    );
    TextEditingController emailController = TextEditingController(text: email);
    TextEditingController genderController = TextEditingController(
      text: gender,
    );
    TextEditingController cnicController = TextEditingController(text: cnic);
    TextEditingController fatherController = TextEditingController(
      text: father,
    );
    TextEditingController addressController = TextEditingController(
      text: address,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Teacher"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField("Name", nameController),
                  _buildTextField("Father Name", fatherController),
                  _buildTextField("Subject", subjectController),
                  _buildTextField("Contact", contactController),
                  _buildTextField("Email", emailController),
                  _buildTextField("Gender", genderController),
                  _buildTextField("CNIC", cnicController),
                  _buildTextField("Address", addressController),
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
                  await firestore.collection('Teachers').doc(docId).update({
                    'name': nameController.text,
                    'Father': fatherController.text,
                    'subject': subjectController.text,
                    'contact': contactController.text,
                    'email': emailController.text,
                    'gender': genderController.text,
                    'cnic': cnicController.text,
                    'address': addressController.text,
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
                onPressed: () async {
                  await firestore.collection('Teachers').doc(docId).delete();
                  Navigator.pop(context);
                  setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Teacher Records')),
        body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          future: _fetchTeachers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            final teachers = snapshot.data ?? [];
            return ListView.builder(
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final doc = teachers[index];
                final teacher = doc.data();

                final List assignedClasses = teacher['assignedClasses'] ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name: ${teacher['name'] ?? 'N/A'}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildTeacherField(
                          "Father Name/ Husband Name",
                          teacher['Father'],
                        ),
                        _buildTeacherField("Subject", teacher['subject']),
                        _CopybuildTeacherField("Contact", teacher['contact']),
                        _buildTeacherField("Gender", teacher['gender']),
                        _CopybuildTeacherField("Email", teacher['email']),
                        _buildTeacherField("Gender", teacher['gender']),
                        _buildTeacherField("CNIC", teacher['cnic']),
                        _buildTeacherField("Address", teacher['address']),
                        const SizedBox(height: 8),
                        if (assignedClasses.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Assigned Classes:",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              ...assignedClasses.map<Widget>((entry) {
                                return RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            "\nClass", // "Section" styled separately
                                        style: const TextStyle(
                                          decoration: TextDecoration.underline,
                                          decorationThickness: 1.2,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: " :-  ${entry['class']} ",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            "\nSection", // "Section" styled separately
                                        style: const TextStyle(
                                          decoration: TextDecoration.underline,
                                          decorationThickness: 1.2,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            " :-  ${entry['section']}", // Section name styled separately
                                        style: const TextStyle(
                                          color:
                                              Colors
                                                  .black, // Change to any color you prefer
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black),
                              onPressed:
                                  () => _showEditTeacherDialog(
                                    doc.id,
                                    teacher['name'] ?? '',
                                    teacher['subject'] ?? '',
                                    teacher['contact'] ?? '',
                                    teacher['email'] ?? '',
                                    teacher['gender'] ?? '',
                                    teacher['cnic'] ?? '',
                                    teacher['father'] ?? '',
                                    teacher['address'] ?? '',
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.black,
                              ),
                              onPressed:
                                  () => _showDeleteConfirmationDialog(
                                    doc.id,
                                    teacher['name'] ?? '',
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
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

// Helper widget to create reusable text fields
Widget _buildTextField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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
