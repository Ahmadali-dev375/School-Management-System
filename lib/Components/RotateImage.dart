// ignore_for_file: file_names, use_super_parameters

import 'package:flutter/material.dart';

class RotatingEarthLogo extends StatefulWidget {
  final double size;
  const RotatingEarthLogo({Key? key, required this.size}) : super(key: key);

  @override
  State<RotatingEarthLogo> createState() => _RotatingEarthLogoState();
}

class _RotatingEarthLogoState extends State<RotatingEarthLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(); // Infinite rotation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Image.asset(
        'assets/econ.jpg',
        height: widget.size,
        width: widget.size,
      ),
    );
  }
}
