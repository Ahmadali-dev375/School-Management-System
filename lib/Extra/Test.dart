// ignore_for_file: file_names

import 'package:flutter/material.dart';

class Testing extends StatelessWidget {
  const Testing({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/econ.jpg', width: 300, height: 300),
            SizedBox(height: 19),
            Text(
              'Noble School System & College',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Way to Success',
              style: TextStyle(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: Color(0xFF8A0204),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
