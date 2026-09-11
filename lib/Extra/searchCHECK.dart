// ignore_for_file: use_super_parameters, file_names, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Screens/ResultFormat.dart';

class SearchStudentScreen extends StatefulWidget {
  const SearchStudentScreen({Key? key}) : super(key: key);

  @override
  State<SearchStudentScreen> createState() => _SearchStudentScreenState();
}

class _SearchStudentScreenState extends State<SearchStudentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedClass;
  String? _selectedSection;

  List<String> _classes = [];
  List<String> _sections = [];

  bool _isLoadingClasses = false;
  bool _isLoadingSections = false;
  bool _classHasSections = true; // Track if a class has sections

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  /// Fetch class names from Firestore
  Future<void> _fetchClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      QuerySnapshot classSnapshot =
          await FirebaseFirestore.instance.collection('Classes').get();

      setState(() {
        _classes = classSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print("Error fetching classes: $e");
    }
    setState(() => _isLoadingClasses = false);
  }

  /// Fetch sections dynamically when a class is selected
  Future<void> _fetchSections(String className) async {
    setState(() {
      _isLoadingSections = true;
      _sections = [];
      _selectedSection = null;
      _classHasSections = true; // Assume sections exist initially
    });

    try {
      QuerySnapshot sectionSnapshot =
          await FirebaseFirestore.instance
              .collection('Classes')
              .doc(className)
              .collection('Sections')
              .get();

      if (sectionSnapshot.docs.isEmpty) {
        // No sections exist, assume students are stored directly under the class
        setState(() {
          _classHasSections = false;
        });
      } else {
        setState(() {
          _sections = sectionSnapshot.docs.map((doc) => doc.id).toList();
        });
      }
    } catch (e) {
      print("Error fetching sections: $e");
    }

    setState(() => _isLoadingSections = false);
  }

  /// Fetch students based on selected class/section
  Stream<List<DocumentSnapshot>> _streamStudents() {
    if (_selectedClass == null) return const Stream.empty();

    if (!_classHasSections) {
      // Class has no sections, fetch students directly from class-level collection
      return FirebaseFirestore.instance
          .collection('Classes')
          .doc(_selectedClass)
          .collection('Students')
          .snapshots()
          .map((snapshot) => snapshot.docs);
    }

    if (_selectedSection != null) {
      // Fetch students from the selected section
      return FirebaseFirestore.instance
          .collection('Classes')
          .doc(_selectedClass)
          .collection('Sections')
          .doc(_selectedSection)
          .collection('Students')
          .snapshots()
          .map((snapshot) => snapshot.docs);
    }

    // Fetch students from all sections (if sections exist)
    return FirebaseFirestore.instance
        .collection('Classes')
        .doc(_selectedClass)
        .collection('Sections')
        .snapshots()
        .asyncMap((sectionSnapshot) async {
          List<Future<QuerySnapshot>> studentFutures =
              sectionSnapshot.docs.map((doc) {
                return FirebaseFirestore.instance
                    .collection('Classes')
                    .doc(_selectedClass)
                    .collection('Sections')
                    .doc(doc.id)
                    .collection('Students')
                    .get();
              }).toList();

          List<QuerySnapshot> studentSnapshots = await Future.wait(
            studentFutures,
          );
          return studentSnapshots.expand((snap) => snap.docs).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Student Results'), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Select Class
              _isLoadingClasses
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Select Class',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _classes.map((className) {
                          return DropdownMenuItem(
                            value: className,
                            child: Text(className),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClass = value;
                        _selectedSection = null;
                      });
                      _fetchSections(value!);
                    },
                  ),
              const SizedBox(height: 10),

              // Select Section (Only if the class has sections)
              if (_classHasSections)
                _isLoadingSections
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                      value: _selectedSection,
                      decoration: const InputDecoration(
                        labelText: 'Select Section (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All Sections"),
                        ),
                        ..._sections.map((sectionName) {
                          return DropdownMenuItem(
                            value: sectionName,
                            child: Text("Section $sectionName"),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSection = value;
                        });
                      },
                    ),
              const SizedBox(height: 10),

              // Search Input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by Name or Roll Number',
                  border: const OutlineInputBorder(),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = "";
                              });
                            },
                          )
                          : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Display Results
              Expanded(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: _streamStudents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No students found."));
                    }

                    var students =
                        snapshot.data!.where((doc) {
                          var data = doc.data() as Map<String, dynamic>?;

                          if (data == null ||
                              !data.containsKey('name') ||
                              !data.containsKey('rollNumber')) {
                            return false;
                          }

                          var studentName =
                              data['name'].toString().trim().toLowerCase();
                          var rollNumber =
                              data['rollNumber']
                                  .toString()
                                  .trim()
                                  .toLowerCase();

                          return studentName.contains(_searchQuery) ||
                              rollNumber.contains(_searchQuery);
                        }).toList();

                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        var student = students[index];
                        var data = student.data() as Map<String, dynamic>;

                        // Create a copy of student data and include document ID
                        var studentData = Map<String, dynamic>.from(data);
                        studentData['id'] = student.id;

                        return ListTile(
                          title: Text(studentData['name']),
                          subtitle: Text(
                            "Roll Number: ${studentData['rollNumber']}",
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => StudentDetailScreen(
                                      studentClass: _selectedClass ?? '',
                                      studentData: studentData,
                                    ),
                              ),
                            );
                          },
                        );
                      },
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
/// Serch