import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15), // Adjust duration for desired speed
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: LoginPageBackgroundPainter(_controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class LoginPageBackgroundPainter extends CustomPainter {
  final double animationValue;

  LoginPageBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.indigo.shade800.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = Colors.blueAccent.shade700.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final paint3 = Paint()
      ..color = Colors.indigo.shade300.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw animated shapes
    _drawShape(canvas, size, paint1, 0.3 + animationValue * 0.2, 0.2 - animationValue * 0.1, math.pi / 4 + animationValue * math.pi / 8);
    _drawShape(canvas, size, paint2, 0.7 - animationValue * 0.2, 0.8 + animationValue * 0.1, -math.pi / 6 + animationValue * math.pi / 10);
    _drawShape(canvas, size, paint3, 0.5 + animationValue * 0.1, 0.5 - animationValue * 0.2, math.pi / 2 + animationValue * math.pi / 12);
  }

  void _drawShape(Canvas canvas, Size size, Paint paint, double centerXRatio, double centerYRatio, double rotationAngle) {
    final centerX = size.width * centerXRatio;
    final centerY = size.height * centerYRatio;
    final radius = size.width * 0.4; // Example radius

    Path path = Path();
    path.moveTo(centerX + radius * math.cos(0 + rotationAngle), centerY + radius * math.sin(0 + rotationAngle));
    for (int i = 1; i <= 5; i++) { // A simple star-like shape
      double angle = (2 * math.pi / 5) * i + rotationAngle;
      path.lineTo(centerX + radius * math.cos(angle), centerY + radius * math.sin(angle));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LoginPageBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
