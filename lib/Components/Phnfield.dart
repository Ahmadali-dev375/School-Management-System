// ignore_for_file: file_names, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInputText extends StatelessWidget {
  final TextEditingController mycontroller;
  final FormFieldValidator<String>? onvalidate;
  final FormFieldSetter<String>? onsubmit;
  final String hint;
  final String? icon;
  final bool showCursor;
  final bool enabled;

  const PhoneInputText({
    required this.mycontroller,
    this.onvalidate,
    this.onsubmit,
    required this.hint,
    this.icon,
    this.showCursor = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: mycontroller,
        validator: onvalidate,
        onSaved: onsubmit,
        keyboardType: TextInputType.phone,
        inputFormatters: [PhoneNumberFormatter()],
        maxLength: 12,
        enabled: enabled,
        showCursor: showCursor,
        cursorWidth: 3,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon:
              icon != null
                  ? Icon(
                    IconData(int.parse(icon!), fontFamily: 'MaterialIcons'),
                    color: const Color(0xFF93E4BE),
                  )
                  : null,
        ),
      ),
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 11 digits
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    String formatted = '';
    int offset = 0;

    // Insert hyphen after 4 digits
    if (digitsOnly.length <= 4) {
      formatted = digitsOnly;
    } else {
      formatted = '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}';
    }

    // Calculate the new cursor position
    int nonDigitCountBeforeCursor =
        newValue.text
            .substring(0, newValue.selection.end)
            .replaceAll(RegExp(r'\d'), '')
            .length;

    offset = newValue.selection.end - nonDigitCountBeforeCursor;

    // Adjust for hyphen
    if (digitsOnly.length > 4 && offset > 4) {
      offset += 1;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, formatted.length),
      ),
    );
  }
}
