// ignore_for_file: unused_element, file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workit/main.dart';

Widget _CopybuildTeacherField(String label, String? value) {
  final isMissing = value == null || value.isEmpty || value == 'N/A';
  final displayText = isMissing ? 'N/A' : value;

  return Padding(
    padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "$label :-  ",
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationThickness: 1.2,
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: SelectableText(
            displayText,
            style: TextStyle(
              fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
              color: isMissing ? const Color(0xFF8A0204) : Colors.black,
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        ),
        if (!isMissing)
          IconButton(
            icon: const Icon(Icons.copy, size: 20, color: Colors.black54),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: displayText));
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
      ],
    ),
  );
}
