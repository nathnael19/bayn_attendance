import 'package:flutter/material.dart';
import '../cubit/attendance_state.dart';

/// The bottom status panel that slides up and shows contextual info based on state.
class AttendanceStatusPanel extends StatelessWidget {
  final AttendanceState state;
  final VoidCallback onRetry;
  final bool faceVisible;

  const AttendanceStatusPanel({
    super.key,
    required this.state,
    required this.onRetry,
    this.faceVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (state is AttendanceSuccess) {
      return _SuccessPanel(state: state as AttendanceSuccess);
    } else if (state is AttendanceFailure) {
      return _FailurePanel(state: state as AttendanceFailure, onRetry: onRetry);
    } else if (state is AttendanceScanning) {
      return const _ScanningPanel(isScanning: true);
    } else {
      return _ScanningPanel(isScanning: false, faceVisible: faceVisible);
    }
  }
}

class _ScanningPanel extends StatefulWidget {
  final bool isScanning;
  final bool faceVisible;
  const _ScanningPanel({this.isScanning = true, this.faceVisible = false});

  @override
  State<_ScanningPanel> createState() => _ScanningPanelState();
}

class _ScanningPanelState extends State<_ScanningPanel> with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        if (_dotController.isCompleted) {
          setState(() {
            _dotCount = (_dotCount % 3) + 1;
          });
          _dotController.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('scanning'),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SCANNING${'.' * _dotCount}',
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              widget.isScanning
                  ? 'Scanning your face'
                  : widget.faceVisible
                      ? 'Hold still...'
                      : 'Face your camera',
              key: ValueKey(widget.isScanning ? 'scan' : widget.faceVisible ? 'hold' : 'wait'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              widget.isScanning
                  ? 'Recognition in progress, please wait'
                  : widget.faceVisible
                      ? 'Face detected — scanning will start soon'
                      : 'Keep your face centered inside the frame',
              key: ValueKey(widget.isScanning ? 'scan_sub' : widget.faceVisible ? 'hold_sub' : 'wait_sub'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // HUD metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MetricChip(label: 'ACCURACY', value: '99.8%', color: const Color(0xFF00E5FF)),
              _MetricChip(label: 'MODE', value: '3D Depth', color: const Color(0xFFCA8A04)),
              _MetricChip(label: 'STATUS', value: 'Active', color: const Color(0xFF00E676)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  final AttendanceSuccess state;

  const _SuccessPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('success'),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF00E676), size: 13),
                SizedBox(width: 6),
                Text(
                  'IDENTITY VERIFIED',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome back,',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.employeeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Time & date chip
          // Details container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, color: Color(0xFFCA8A04), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Clocked in at ${state.time}',
                      style: const TextStyle(
                        color: Color(0xFFCA8A04),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                if (state.confidence > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.analytics_outlined, color: Color(0xFF00E5FF), size: 16),
                      const SizedBox(width: 10),
                      Text(
                        'Accuracy: ${(state.confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Have a great day! Your attendance is logged.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  final AttendanceFailure state;
  final VoidCallback onRetry;

  const _FailurePanel({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('failure'),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF1744).withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFFF1744), size: 13),
                SizedBox(width: 6),
                Text(
                  'VERIFICATION FAILED',
                  style: TextStyle(
                    color: Color(0xFFFF1744),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Face not recognized',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure your face is well-lit and centered',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCA8A04), Color(0xFFD97706)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCA8A04).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: Color(0xFF1C1917), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        color: Color(0xFF1C1917),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
