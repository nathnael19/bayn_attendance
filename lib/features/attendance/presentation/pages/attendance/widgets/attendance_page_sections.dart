import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../cubit/attendance_state.dart';
import '../../../widgets/attendance_status_panel.dart';
import '../../../widgets/biometric_scan_frame.dart';

class AttendanceFaceHint extends StatelessWidget {
  final Animation<double> animation;

  const AttendanceFaceHint({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Center(
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, __) => Opacity(
                opacity: 0.5 + 0.5 * animation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.center_focus_strong_rounded,
                        color: Color(0xFF00E5FF),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Position your face in the frame',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AttendanceBackground extends StatelessWidget {
  final bool isCameraInitialized;
  final CameraController? cameraController;
  final Color scaffoldColor;

  const AttendanceBackground({
    super.key,
    required this.isCameraInitialized,
    required this.cameraController,
    required this.scaffoldColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isCameraInitialized && cameraController != null)
          Positioned.fill(child: CameraPreview(cameraController!))
        else
          Positioned.fill(child: Container(color: scaffoldColor)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  scaffoldColor.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [scaffoldColor, Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [scaffoldColor, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AttendanceParticles extends StatelessWidget {
  final Animation<double> animation;

  const AttendanceParticles({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) =>
            CustomPaint(painter: AttendanceParticlePainter(animation.value)),
      ),
    );
  }
}

class AttendanceHeader extends StatelessWidget {
  final AttendanceState state;
  final bool faceVisible;
  final Animation<double> headerGlowAnimation;
  final VoidCallback onBack;

  const AttendanceHeader({
    super.key,
    required this.state,
    required this.faceVisible,
    required this.headerGlowAnimation,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.7);
    final iconBgColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final iconBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                border: Border.all(color: iconBorderColor),
              ),
              child: Icon(Icons.arrow_back_rounded, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: headerGlowAnimation,
                builder: (_, __) => Text(
                  'BAYN',
                  style: TextStyle(
                    color: Color.lerp(
                      const Color(0xFFCA8A04),
                      const Color(0xFFFFD700),
                      headerGlowAnimation.value,
                    ),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
              Text(
                'Face Scan',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.45),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          _LiveIndicator(state: state, faceVisible: faceVisible),
        ],
      ),
    );
  }
}

class AttendanceScanArea extends StatelessWidget {
  final AttendanceState state;
  final bool faceVisible;

  const AttendanceScanArea({
    super.key,
    required this.state,
    required this.faceVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GlitchText(
            text: state is AttendanceScanning
                ? 'SCANNING'
                : state is AttendanceSuccess
                ? 'SCAN COMPLETE'
                : state is AttendanceFailure
                ? 'SCAN FAILED'
                : faceVisible
                ? 'FACE DETECTED'
                : 'WAITING',
            color: state is AttendanceSuccess
                ? const Color(0xFF00E676)
                : state is AttendanceFailure
                ? const Color(0xFFFF1744)
                : faceVisible
                ? const Color(0xFF00E5FF)
                : const Color(0xFF00E5FF).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 28),
          BiometricScanFrame(state: state),
          const SizedBox(height: 28),
          if (state is AttendanceScanning || state is AttendanceInitial)
            _AlignmentGuide(active: faceVisible),
        ],
      ),
    );
  }
}

class AttendanceStatusCard extends StatelessWidget {
  final BuildContext context;
  final AttendanceState state;
  final bool faceVisible;
  final VoidCallback onRetry;

  const AttendanceStatusCard({
    super.key,
    required this.context,
    required this.state,
    required this.faceVisible,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF111118) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFE5D8C5);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AttendanceStatusPanel(
          state: state,
          faceVisible: faceVisible,
          onRetry: onRetry,
        ),
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  final AttendanceState state;
  final bool faceVisible;

  const _LiveIndicator({required this.state, required this.faceVisible});

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.state is AttendanceSuccess;
    final isFailure = widget.state is AttendanceFailure;
    final isScanning = widget.state is AttendanceScanning;

    final label = isSuccess
        ? 'VERIFIED'
        : isFailure
        ? 'FAILED'
        : isScanning
        ? 'SCANNING'
        : widget.faceVisible
        ? 'FACE FOUND'
        : 'WAITING';

    final color = isSuccess
        ? const Color(0xFF00E676)
        : isFailure
        ? const Color(0xFFFF1744)
        : isScanning
        ? const Color(0xFF00E5FF)
        : widget.faceVisible
        ? const Color(0xFF00E5FF)
        : (Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.3));

    return AnimatedBuilder(
      animation: _blink,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isSuccess || isFailure ? 1 : _blink.value,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlignmentGuide extends StatelessWidget {
  final bool active;
  const _AlignmentGuide({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final isCenter = i == 2;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isCenter ? 20 : 5,
            height: 2,
            decoration: BoxDecoration(
              color: const Color(
                0xFF00E5FF,
              ).withValues(alpha: isCenter ? 0.6 : 0.2),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }
}

class _GlitchText extends StatefulWidget {
  final String text;
  final Color color;

  const _GlitchText({required this.text, required this.color});

  @override
  State<_GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<_GlitchText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
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
      builder: (_, __) {
        final flicker = _controller.value > 0.92 && _controller.value < 0.95
            ? 0.4
            : 1.0;
        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: widget.color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: widget.color.withValues(alpha: 0.7),
                blurRadius: 12,
              ),
            ],
          ),
          child: Opacity(opacity: flicker, child: Text(widget.text)),
        );
      },
    );
  }
}

class AttendanceParticlePainter extends CustomPainter {
  final double t;

  static final _rand = math.Random(42);
  static final List<_Particle> _particles = List.generate(
    18,
    (_) => _Particle(
      x: _rand.nextDouble(),
      y: _rand.nextDouble(),
      speed: 0.04 + _rand.nextDouble() * 0.06,
      size: 1.0 + _rand.nextDouble() * 1.5,
      opacity: 0.08 + _rand.nextDouble() * 0.14,
    ),
  );

  const AttendanceParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = ((p.y - t * p.speed) % 1.0) * size.height;
      final x = p.x * size.width;
      canvas.drawCircle(
        Offset(x, y),
        p.size,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: p.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(AttendanceParticlePainter old) => old.t != t;
}

class _Particle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final double opacity;

  const _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}
