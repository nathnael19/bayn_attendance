import 'package:flutter/material.dart';
import '../cubit/attendance_state.dart';
import 'scan_frame_painter.dart';

/// Animated scanning line that sweeps up and down inside the scan frame.
class ScanLine extends StatefulWidget {
  const ScanLine({super.key});

  @override
  State<ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Align(
          alignment: Alignment(0, (_animation.value * 2) - 1),
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF00E5FF).withValues(alpha: 0.9),
                  const Color(0xFF00E5FF),
                  const Color(0xFF00E5FF).withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pulsing ring widget for the scanning state.
class PulseRing extends StatefulWidget {
  final Color color;
  final double size;

  const PulseRing({super.key, required this.color, required this.size});

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _scaleAnim = Tween(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnim = Tween(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The main biometric scan frame widget with state-aware visuals.
class BiometricScanFrame extends StatelessWidget {
  final AttendanceState state;

  const BiometricScanFrame({super.key, required this.state});

  Color get _frameColor {
    if (state is AttendanceSuccess) return const Color(0xFF00E676);
    if (state is AttendanceFailure) return const Color(0xFFFF1744);
    return const Color(0xFF00E5FF);
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = state is AttendanceSuccess;
    final isFailure = state is AttendanceFailure;
    final isScanning = state is AttendanceScanning || state is AttendanceInitial;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: 280,
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring (scanning only)
          if (isScanning)
            PulseRing(color: _frameColor.withValues(alpha: 0.3), size: 310),

          // Frame glow background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _frameColor.withValues(alpha: isSuccess || isFailure ? 0.4 : 0.2),
                  blurRadius: isSuccess ? 40 : 20,
                  spreadRadius: isSuccess ? 4 : 1,
                ),
              ],
            ),
          ),

          // HUD bracket corners
          Positioned.fill(
            child: CustomPaint(
              painter: ScanFramePainter(color: _frameColor),
            ),
          ),

          // Scanning line (only while scanning)
          if (isScanning)
            const Positioned.fill(
              child: ClipRect(child: ScanLine()),
            ),

          // Grid pattern overlay (subtle)
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),

          // Dot pattern in center
          if (!isSuccess && !isFailure)
            Positioned(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.face_retouching_natural,
                    size: 64,
                    color: _frameColor.withValues(alpha: 0.15),
                  ),
                ],
              ),
            ),

          // Success checkmark
          if (isSuccess)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFF00E676), width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF00E676),
                    size: 44,
                  ),
                ),
              ),
            ),

          // Failure X mark
          if (isFailure)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF1744).withValues(alpha: 0.12),
                    border: Border.all(color: const Color(0xFFFF1744), width: 2),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFFF1744),
                    size: 44,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A subtle background grid painter for the cyberpunk HUD aesthetic.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 0.5;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
