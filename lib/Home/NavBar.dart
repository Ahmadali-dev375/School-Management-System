// ignore_for_file: file_names, avoid_print, no_leading_underscores_for_local_identifiers

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:workit/Home/House.dart';

// Screens
import '../Extra/searchCHECK.dart';
import '../Screens/AddStudent.dart';
import '../Screens/MarksAdding.dart';
import '../Screens/Records.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();
  int _selectedIndex = 0;
  String teacherCnic = "";
  bool isLoading = true;

  final List<String> _labels = [
    'Home',
    'Adding',
    'Records',
    'Marking',
    'Results',
  ];
  final List<IconData> _icons = [
    Icons.home,
    Icons.person_add,
    Icons.school,
    Icons.add,
    Icons.assignment_turned_in_outlined,
  ];

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
            teacherCnic = (data['cnic'] ?? "").trim();
            isLoading = false;
          });
        } else {
          print("Teacher not found");
          setState(() => isLoading = false);
        }
      } catch (e) {
        print("Error loading teacher data: $e");
        setState(() => isLoading = false);
      }
    } else {
      print("User not logged in");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> _screens = [
      const TeachHome(),
      const AddStudentScreen(),
      const StudentsScreen(),
      AddMarksScreen(teacherCnic: teacherCnic),
      SearchStudentScreen(),
    ];

    return SafeArea(
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: CurvedNavigationBar(
          key: _navKey,
          index: _selectedIndex,
          height: 65.0,
          backgroundColor: Colors.white,
          color: const Color(0xFF1B7FEE),
          buttonBackgroundColor: const Color(0xFF1B7FEE),
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 400),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: List.generate(_icons.length, (index) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icons[index], size: 28, color: Colors.white),
                if (_selectedIndex != index)
                  Text(
                    _labels[index],
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
