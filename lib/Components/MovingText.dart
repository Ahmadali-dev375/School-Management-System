// ignore_for_file: use_super_parameters, file_names, library_private_types_in_public_api

import 'package:flutter/material.dart';

class AnimatedMovingText extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final Duration duration;

  const AnimatedMovingText({
    Key? key,
    required this.text,
    this.fontSize = 18,
    this.fontWeight = FontWeight.bold,
    this.color = Colors.white,
    this.duration = const Duration(seconds: 10),
  }) : super(key: key);

  @override
  _AnimatedMovingTextState createState() => _AnimatedMovingTextState();
}

class _AnimatedMovingTextState extends State<AnimatedMovingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(); // Infinite left scroll

    _animation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Start off screen right
      end: const Offset(1.0, 0.0), // Move to off screen left
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SlideTransition(
        position: _animation,
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
