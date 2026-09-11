// ignore_for_file: file_names, avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:workit/Auth/Login.dart';
import 'package:workit/Components/MovingText.dart';
import 'package:workit/Components/RotateImage.dart';
import 'package:workit/Widgets/AdminButton.dart';

class TeachHome extends StatefulWidget {
  const TeachHome({super.key});

  @override
  State<TeachHome> createState() => _TeachHomeState();
}

class _TeachHomeState extends State<TeachHome>
    with SingleTickerProviderStateMixin {
  String teacherName = "Loading...";
  String teacherCnic = "";
  String fatherName = "";
  String subject = "";
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadTeacherData();
    _animateAppBarTitle();
  }

  void _animateAppBarTitle() {
    Future.delayed(const Duration(seconds: 1), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 5),
        curve: Curves.linear,
      );
    });
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
            fatherName = data['Father'] ?? "N/A";
            subject = data['subject'] ?? "N/A";
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

  void _logout(BuildContext context) async {
    final confirmed = await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              ElevatedButton(
                child: const Text("Logout"),
                onPressed: () async {
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
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pop(); // Navigate back to login
    }
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow("Name", teacherName),
            _infoRow("Father's Name", fatherName),
            _infoRow("CNIC", teacherCnic),

            _infoRow("Subject", subject),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color:
                Theme.of(
                  context,
                ).appBarTheme.backgroundColor, // or a specific color
            padding: const EdgeInsets.symmetric(
              horizontal: 0,
            ), // Removes leading space
            child: Row(
              children: [
                PassButton(),
                Expanded(
                  child: AnimatedMovingText(
                    text: 'Noble School System and College',
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "Teacher DashBoard",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8a0204),
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoCard(),
                  const SizedBox(height: 15),
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
                  const SizedBox(height: 44),
                  const RotatingEarthLogo(size: 250),
                  const SizedBox(height: 8),
                  const Text(
                    "Empowering Education Through Innovation",
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text("Logout"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            243,
                            245,
                            244,
                          ),
                          foregroundColor: const Color(0xFF8A0204),
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
        ),
      ),
    );
  }
}
