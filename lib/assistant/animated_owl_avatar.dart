import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum OwlMood { idle, helpful, happy, alert, talking }

class AnimatedOwlAvatar extends StatefulWidget {
  final double size;
  final OwlMood mood;

  const AnimatedOwlAvatar({
    super.key,
    required this.size,
    required this.mood,
  });

  @override
  State<AnimatedOwlAvatar> createState() => _AnimatedOwlAvatarState();
}

class _AnimatedOwlAvatarState extends State<AnimatedOwlAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _blinkController;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scheduleNextBlink();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idleController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    final millis = 2400 + math.Random().nextInt(1800);
    _blinkTimer = Timer(Duration(milliseconds: millis), () {
      if (!mounted) return;
      _blinkController.forward(from: 0);
      _scheduleNextBlink();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _blinkController]),
      builder: (context, _) {
        final cycle = _idleController.value;
        final blink = math.sin(_blinkController.value * math.pi).clamp(0.0, 1.0);
        final bob = math.sin(cycle * math.pi * 2) * size * 0.020;
        final happyBounce = widget.mood == OwlMood.happy
            ? math.sin(cycle * math.pi * 4).abs() * size * 0.018
            : 0.0;
        final alertShake = widget.mood == OwlMood.alert
            ? math.sin(cycle * math.pi * 16) * size * 0.012
            : 0.0;
        final talkPulse = widget.mood == OwlMood.talking
            ? math.sin(cycle * math.pi * 6).abs()
            : 0.0;
        final helpfulLook = widget.mood == OwlMood.alert ? 0.18 : 0.12;
        final lookX = math.sin(cycle * math.pi * 2) * size * helpfulLook * 0.12;
        final lookY = math.cos(cycle * math.pi * 1.4) * size * 0.05;
        final wingLift = widget.mood == OwlMood.talking
            ? 0.28 + (talkPulse * 0.12)
            : widget.mood == OwlMood.happy
            ? 0.18
            : widget.mood == OwlMood.alert
            ? 0.10
            : 0.05;
        final headTilt = lookX * 0.16;
        final browTilt = widget.mood == OwlMood.alert
            ? 0.40
            : widget.mood == OwlMood.happy
            ? -0.22
            : 0.0;

        return Transform.translate(
          offset: Offset(alertShake, bob - happyBounce),
          child: SizedBox(
            width: size,
            height: size * 1.08,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: size * 0.02,
                  child: Container(
                    width: size * 0.52,
                    height: size * 0.10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(size),
                    ),
                  ),
                ),
                Positioned(
                  top: size * 0.05,
                  left: size * 0.16,
                  child: Transform.rotate(
                    angle: -0.18 - (talkPulse * 0.06),
                    alignment: Alignment.bottomCenter,
                    child: _ear(size * 0.16, const Color(0xFF8B4513)),
                  ),
                ),
                Positioned(
                  top: size * 0.05,
                  right: size * 0.16,
                  child: Transform.rotate(
                    angle: 0.18 + (talkPulse * 0.06),
                    alignment: Alignment.bottomCenter,
                    child: _ear(size * 0.16, const Color(0xFF8B4513)),
                  ),
                ),
                Positioned(
                  bottom: size * 0.21,
                  left: size * 0.01,
                  child: Transform.rotate(
                    angle: -(0.34 + wingLift),
                    alignment: Alignment.centerRight,
                    child: _wing(
                      width: size * 0.23,
                      height: size * 0.44,
                      outerColor: const Color(0xFF8B4513),
                      innerColor: const Color(0xFFA0522D),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size * 0.21,
                  right: size * 0.01,
                  child: Transform.rotate(
                    angle: 0.34 + wingLift,
                    alignment: Alignment.centerLeft,
                    child: _wing(
                      width: size * 0.23,
                      height: size * 0.44,
                      outerColor: const Color(0xFF8B4513),
                      innerColor: const Color(0xFFA0522D),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size * 0.12,
                  child: _ellipse(
                    width: size * 0.60,
                    height: size * 0.72,
                    color: const Color(0xFF8B4513),
                  ),
                ),
                Positioned(
                  bottom: size * 0.20,
                  child: _ellipse(
                    width: size * 0.34,
                    height: size * 0.44,
                    color: const Color(0xFFD2B48C),
                  ),
                ),
                Positioned(
                  bottom: size * 0.15,
                  child: _chestPattern(size),
                ),
                Positioned(
                  top: size * 0.10,
                  child: Transform.rotate(
                    angle: headTilt * 0.01,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _circle(size * 0.48, const Color(0xFF8B4513)),
                        Positioned(
                          left: size * 0.07,
                          top: size * 0.11,
                          child: _eyebrow(
                            width: size * 0.12,
                            angle: -0.16 - browTilt,
                          ),
                        ),
                        Positioned(
                          right: size * 0.07,
                          top: size * 0.11,
                          child: _eyebrow(
                            width: size * 0.12,
                            angle: 0.16 + browTilt,
                          ),
                        ),
                        Positioned(
                          left: size * 0.10,
                          top: size * 0.13,
                          child: _eye(
                            eyeSize: size * 0.17,
                            lookOffset: Offset(lookX, lookY),
                            blinkAmount: blink.toDouble(),
                          ),
                        ),
                        Positioned(
                          right: size * 0.10,
                          top: size * 0.13,
                          child: _eye(
                            eyeSize: size * 0.17,
                            lookOffset: Offset(lookX, lookY),
                            blinkAmount: blink.toDouble(),
                          ),
                        ),
                        Positioned(
                          top: size * 0.28,
                          child: _beak(
                            width: size * 0.16,
                            height: size * (widget.mood == OwlMood.talking
                                ? 0.18 + (talkPulse * 0.03)
                                : 0.16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: size * 0.00,
                  child: _feet(size),
                ),
                if (widget.mood == OwlMood.happy)
                  Positioned(
                    top: size * 0.00,
                    right: size * 0.05,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: const Color(0xFFFBBF24),
                      size: size * 0.10,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ear(double size, Color color) {
    return CustomPaint(
      size: Size(size, size * 1.45),
      painter: _EarPainter(color: color),
    );
  }

  Widget _wing({
    required double width,
    required double height,
    required Color outerColor,
    required Color innerColor,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ellipse(width: width, height: height, color: outerColor),
          Positioned(
            left: width * 0.10,
            child: _ellipse(
              width: width * 0.70,
              height: height * 0.84,
              color: innerColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow({required double width, required double angle}) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: width * 0.12,
        decoration: BoxDecoration(
          color: const Color(0xFF5C3317),
          borderRadius: BorderRadius.circular(width),
        ),
      ),
    );
  }

  Widget _eye({
    required double eyeSize,
    required Offset lookOffset,
    required double blinkAmount,
  }) {
    return SizedBox(
      width: eyeSize,
      height: eyeSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _circle(eyeSize, const Color(0xFFF5F5DC)),
          _circle(eyeSize * 0.92, Colors.white),
          Transform.translate(
            offset: Offset(lookOffset.dx * 0.12, lookOffset.dy * 0.10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _circle(eyeSize * 0.52, const Color(0xFFFFD700)),
                _circle(eyeSize * 0.34, Colors.black),
                Positioned(
                  top: eyeSize * 0.18,
                  right: eyeSize * 0.24,
                  child: _circle(eyeSize * 0.10, Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          ClipOval(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: blinkAmount,
              child: _circle(eyeSize, const Color(0xFF8B4513)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _beak({required double width, required double height}) {
    return CustomPaint(
      size: Size(width, height),
      painter: const _BeakPainter(),
    );
  }

  Widget _feet(double size) {
    return SizedBox(
      width: size * 0.34,
      height: size * 0.14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _foot(size * 0.12),
          _foot(size * 0.12),
        ],
      ),
    );
  }

  Widget _foot(double width) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: width * 0.20,
              height: width * 0.45,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00),
                borderRadius: BorderRadius.circular(width),
              ),
            ),
          ),
          _ellipse(
            width: width,
            height: width * 0.34,
            color: const Color(0xFFFF8C00),
          ),
        ],
      ),
    );
  }

  Widget _chestPattern(double size) {
    return SizedBox(
      width: size * 0.30,
      height: size * 0.32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          5,
          (index) => _ellipse(
            width: size * (0.22 - (index * 0.008)),
            height: size * 0.028,
            color: const Color(0xFF8B4513).withOpacity(0.16),
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _ellipse({
    required double width,
    required double height,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}

class _EarPainter extends CustomPainter {
  final Color color;

  const _EarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.52, size.height)
      ..quadraticBezierTo(
        size.width * 0.00,
        size.height * 0.55,
        size.width * 0.30,
        size.height * 0.00,
      )
      ..quadraticBezierTo(
        size.width * 0.48,
        -size.height * 0.05,
        size.width * 0.62,
        size.height * 0.08,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.52,
        size.width * 0.52,
        size.height,
      )
      ..close();

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);

    final innerPath = Path()
      ..moveTo(size.width * 0.50, size.height * 0.80)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.52,
        size.width * 0.38,
        size.height * 0.22,
      )
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.18,
        size.width * 0.58,
        size.height * 0.26,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.52,
        size.width * 0.50,
        size.height * 0.80,
      )
      ..close();

    canvas.drawPath(
      innerPath,
      Paint()..color = const Color(0xFFA0522D),
    );
  }

  @override
  bool shouldRepaint(covariant _EarPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _BeakPainter extends CustomPainter {
  const _BeakPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final topPath = Path()
      ..moveTo(size.width * 0.50, 0)
      ..lineTo(size.width * 0.05, size.height * 0.45)
      ..lineTo(size.width * 0.50, size.height * 0.62)
      ..lineTo(size.width * 0.95, size.height * 0.45)
      ..close();

    final bottomPath = Path()
      ..moveTo(size.width * 0.50, size.height * 0.62)
      ..lineTo(size.width * 0.18, size.height * 0.98)
      ..lineTo(size.width * 0.50, size.height)
      ..lineTo(size.width * 0.82, size.height * 0.98)
      ..close();

    canvas.drawPath(topPath, Paint()..color = const Color(0xFFFF8C00));
    canvas.drawPath(bottomPath, Paint()..color = const Color(0xFFFF7F00));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
