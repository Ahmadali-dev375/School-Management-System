// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:workit/Auth/Login.dart';
import 'package:workit/Auth/Reset.dart';
import 'package:workit/Components/MovingText.dart';
import 'package:workit/Extra/searchCHECK.dart';
import 'package:workit/Screens/AddStudent.dart';
import 'package:workit/Screens/AddSubjects.dart';
import 'package:workit/Screens/AddTeacher.dart';
import 'package:workit/Screens/ManageClass.dart';
import 'package:workit/Screens/Records.dart';
import 'package:workit/Screens/RecordsTeach.dart';
import 'package:workit/Screens/AdminPerm.dart';
import '../Components/RotateImage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String teacherName = "Loading...";
  String teacherCnic = "";

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final query =
            await FirebaseFirestore.instance
                .collection('Teachers')
                .where('email', isEqualTo: user.email)
                .limit(1)
                .get();

        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          setState(() {
            teacherName = data['name'] ?? "Unnamed";
            teacherCnic = (data['cnic'] ?? "").trim();
          });
        } else {
          setState(() => teacherName = "Teacher Not Found");
        }
      } catch (e) {
        print("Error: $e");
        setState(() => teacherName = "Error Loading");
      }
    } else {
      setState(() => teacherName = "Not Logged In");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Stops auto-leading icon
          titleSpacing: 0, // Removes default leading space
          title: Row(
            children: [
              Builder(
                builder:
                    (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedMovingText(
                  text: 'Noble School System and College',
                ),
              ),
            ],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.school,
                        size: 30,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Admin Panel",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSectionHeader("Admin Tools"),
              _buildDrawerItem(
                Icons.person_add,
                'Add Student',
                const AddStudentScreen(),
              ),
              _buildDrawerItem(
                Icons.person_add_alt_1,
                'Add Teacher',
                const AddTeacherScreen(),
              ),
              _buildDrawerItem(
                Icons.school,
                'Student Records',
                const StudentsScreen(),
              ),
              _buildDrawerItem(
                Icons.people_outline,
                'Teacher Records',
                const TeachersScreen(),
              ),
              _buildDrawerItem(
                Icons.assignment_turned_in_outlined,
                'Results',
                const SearchStudentScreen(),
              ),

              const Divider(),

              _buildSectionHeader("Admin Area"),
              _buildDrawerItem(
                Icons.menu_book,
                'Create Classes',
                const AddClassWithSubjectsScreen(),
              ),
              _buildDrawerItem(
                Icons.class_,
                'Manage Classes',
                EditClassSubjectsScreen(),
              ),
              _buildDrawerItem(
                Icons.admin_panel_settings,
                'Teacher Permission',
                AdminTeacherPermissions(),
              ),

              const SizedBox(height: 50),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherLoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Text(
                "Admin Panel",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8a0204),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 50),
              const RotatingEarthLogo(size: 250),
              const SizedBox(height: 30),
              // App name with branding
              Text(
                "Noble School System & College",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              // Slogan
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFc3e3d6),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "Way to Success",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8a0204),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Empowering Education Through Innovation",
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 50),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResetAdminPasswordScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restore_page, size: 18),
                    label: const Text("Reset"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 243, 245, 244),
                      foregroundColor: Color(0xFF8A0204),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
