// ignore_for_file: file_names, non_constant_identifier_names, library_private_types_in_public_api, prefer_const_constructors_in_immutables, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputText extends StatefulWidget {
  final TextEditingController mycontroller;
  final FormFieldValidator<String>? onvalidate;
  final FormFieldSetter<String>? onsubmit;
  final TextInputType keyboard;
  final String hint;
  final String? icon;
  final String? icons;
  final bool Cursor;
  final bool obsure;
  final bool enable;
  final bool auto;
  final bool isCNIC; // New property to detect CNIC input

  InputText({
    required this.mycontroller,
    this.onvalidate,
    this.onsubmit,
    required this.keyboard,
    required this.hint,
    this.obsure = false,
    required this.Cursor,
    this.icon,
    this.icons,
    this.enable = true,
    this.auto = false,
    this.isCNIC = false, // Default false unless specified
  });

  @override
  _InputTextState createState() => _InputTextState();
}

class _InputTextState extends State<InputText> {
  bool isHidden = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        showCursor: widget.Cursor,
        controller: widget.mycontroller,
        validator: widget.onvalidate,
        onSaved: widget.onsubmit,
        keyboardType: widget.keyboard,
        obscureText: isHidden ? widget.obsure : false,

        cursorWidth: 3,
        inputFormatters: widget.isCNIC ? [CNICInputFormatter()] : [],
        maxLength: widget.isCNIC ? 15 : null, // Max length for CNIC
        decoration: InputDecoration(
          suffixIcon:
              widget.icons != null
                  ? GestureDetector(
                    onTap: () {
                      setState(() {
                        isHidden = !isHidden;
                      });
                    },
                    child: Icon(
                      isHidden ? Icons.visibility : Icons.visibility_off,
                      color: Color(0xFF9D9BA4),
                    ),
                  )
                  : null,
          hintText: widget.hint,
          prefixIcon:
              widget.icon != null
                  ? Icon(
                    IconData(
                      int.parse(widget.icon!),
                      fontFamily: 'MaterialIcons',
                    ),
                    color: Color(0xFF93E4BE),
                  )
                  : null,
        ),
      ),
    );
  }
}

class CNICInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(
      RegExp(r'\D'),
      '',
    ); // Remove non-digits

    if (digitsOnly.length > 13) {
      digitsOnly = digitsOnly.substring(0, 13); // Limit to 13 digits
    }

    String formattedCNIC = '';

    if (digitsOnly.length > 5) {
      formattedCNIC = '${digitsOnly.substring(0, 5)}-';
      if (digitsOnly.length > 12) {
        formattedCNIC +=
            '${digitsOnly.substring(5, 12)}-${digitsOnly.substring(12)}';
      } else if (digitsOnly.length > 5) {
        formattedCNIC += digitsOnly.substring(5);
      }
    } else {
      formattedCNIC = digitsOnly;
    }

    return TextEditingValue(
      text: formattedCNIC,
      selection: TextSelection.collapsed(offset: formattedCNIC.length),
    );
  }
}
