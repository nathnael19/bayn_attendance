import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../utils/camera_vision_utils.dart';
import '../models/register_face_angle.dart';

class RegisterCaptureStep extends StatefulWidget {
  final String personName;
  final void Function(Map<FaceAngle, List<String>> shots) onComplete;

  const RegisterCaptureStep({
    super.key,
    required this.personName,
    required this.onComplete,
  });

  @override
  State<RegisterCaptureStep> createState() => _RegisterCaptureStepState();
}

class _RegisterCaptureStepState extends State<RegisterCaptureStep>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  bool _cameraReady = false;

  late final FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _faceVisible = false;
  bool _poseMatched = false;

  final _angles = FaceAngle.values;
  int _angleIndex = 0;

  final Map<FaceAngle, List<String>> _shots = {
    for (final angle in FaceAngle.values) angle: [],
  };

  static const int _shotsPerAngle = 3;
  bool _capturing = false;
  bool _autoCaptureQueued = false;
  DateTime? _lastAutoCaptureAt;

  late AnimationController _ringController;
  late AnimationController _flashController;
  late Animation<double> _flashAnim;

  FaceAngle get _currentAngle => _angles[_angleIndex];
  List<String> get _currentShots => _shots[_currentAngle]!;

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashAnim = CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeOut,
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = CameraVisionUtils.selectFrontCamera(cameras);
      if (front == null) return;
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _frontCamera = front;
        _cameraReady = true;
      });
      controller.startImageStream(_processFrame);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDetecting || _capturing) return;
    _isDetecting = true;
    try {
      final front = _frontCamera;
      if (front == null) return;
      final inputImage = CameraVisionUtils.createInputImage(image, front);

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      final hasFace = faces.isNotEmpty;
      if (hasFace != _faceVisible) {
        setState(() => _faceVisible = hasFace);
      }

      final poseMatched = hasFace && _isPoseMatched(faces.first, _currentAngle);
      if (poseMatched != _poseMatched) {
        setState(() => _poseMatched = poseMatched);
      }

      if (poseMatched && _currentShots.length < _shotsPerAngle) {
        _scheduleAutoCapture();
      }
    } catch (_) {
    } finally {
      _isDetecting = false;
    }
  }

  bool _isPoseMatched(Face face, FaceAngle angle) {
    final yaw = face.headEulerAngleY ?? 0;
    final pitch = face.headEulerAngleX ?? 0;

    switch (angle) {
      case FaceAngle.front:
        return yaw.abs() <= 12 && pitch.abs() <= 12;
      case FaceAngle.left:
        return yaw <= -12;
      case FaceAngle.right:
        return yaw >= 12;
      case FaceAngle.up:
        return pitch <= -10;
      case FaceAngle.down:
        return pitch >= 10;
    }
  }

  void _scheduleAutoCapture() {
    if (_capturing || _autoCaptureQueued || !_faceVisible || !_poseMatched) {
      return;
    }
    if (_currentShots.length >= _shotsPerAngle) return;

    final now = DateTime.now();
    if (_lastAutoCaptureAt != null &&
        now.difference(_lastAutoCaptureAt!) <
            const Duration(milliseconds: 650)) {
      return;
    }

    _autoCaptureQueued = true;
    Future.delayed(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      _autoCaptureQueued = false;
      if (!_faceVisible ||
          !_poseMatched ||
          _capturing ||
          _currentShots.length >= _shotsPerAngle) {
        return;
      }

      _lastAutoCaptureAt = DateTime.now();
      await _captureShot();
    });
  }

  Future<void> _captureShot() async {
    if (!_cameraReady ||
        _cameraController == null ||
        !_faceVisible ||
        !_poseMatched ||
        _capturing) {
      return;
    }

    setState(() => _capturing = true);
    _flashController.forward(from: 0);

    try {
      await _cameraController!.stopImageStream();
      final xFile = await _cameraController!.takePicture();
      await _cameraController!.startImageStream(_processFrame);

      if (!mounted) return;
      setState(() {
        _currentShots.add(xFile.path);
        _capturing = false;
      });

      if (_currentShots.length >= _shotsPerAngle) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        if (_angleIndex < _angles.length - 1) {
          setState(() => _angleIndex++);
        } else {
          _cameraController?.stopImageStream();
          widget.onComplete(_shots);
        }
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.dispose();
    _faceDetector.close();
    _ringController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDone = _shots.values.fold(0, (sum, list) => sum + list.length);
    final totalNeeded = _angles.length * _shotsPerAngle;
    final progress = totalDone / totalNeeded;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE6DAC7),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.personName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F1A14),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Biometric capture in progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.48)
                                  : const Color(
                                      0xFF1F1A14,
                                    ).withValues(alpha: 0.52),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MiniStatusPill(
                      text: '$totalDone / $totalNeeded',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFEDE4D7),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFCA8A04)),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _angles.length,
            itemBuilder: (context, i) {
              final angle = _angles[i];
              final done = _shots[angle]!.length >= _shotsPerAngle;
              final active = i == _angleIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF00E676).withValues(alpha: 0.15)
                      : active
                      ? const Color(0xFFCA8A04).withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: done
                        ? const Color(0xFF00E676).withValues(alpha: 0.5)
                        : active
                        ? const Color(0xFFCA8A04).withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      done ? Icons.check_circle_rounded : angle.icon,
                      size: 13,
                      color: done
                          ? const Color(0xFF00E676)
                          : active
                          ? const Color(0xFFCA8A04)
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      angle.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active || done
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: done
                            ? const Color(0xFF00E676)
                            : active
                            ? const Color(0xFFCA8A04)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_cameraReady && _cameraController != null)
                ClipRRect(child: CameraPreview(_cameraController!))
              else
                Container(
                  color: const Color(0xFF0A0A0E),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFCA8A04),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.85,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _ringController,
                  builder: (_, __) {
                    return CustomPaint(
                      size: const Size(250, 250),
                      painter: _RingPainter(
                        progress: _ringController.value,
                        faceVisible: _faceVisible,
                        shotProgress: _currentShots.length / _shotsPerAngle,
                      ),
                    );
                  },
                ),
              ),
              FadeTransition(
                opacity: _flashAnim.drive(
                  Tween(
                    begin: 0.0,
                    end: 0.6,
                  ).chain(CurveTween(curve: const Interval(0, 0.4))),
                ),
                child: Container(color: Colors.white),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_shotsPerAngle, (i) {
                        final taken = i < _currentShots.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: taken ? 24 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: taken
                                ? const Color(0xFF00E676)
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: _poseMatched
                              ? const Color(0xFF00E676).withValues(alpha: 0.5)
                              : _faceVisible
                              ? const Color(0xFFCA8A04).withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _currentAngle.label,
                            style: const TextStyle(
                              color: Color(0xFFE8B04A),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _poseMatched
                                ? 'Hold still. Capturing automatically.'
                                : 'Align this pose to continue.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _poseMatched
                            ? const Color(0xFF00E676).withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _poseMatched
                              ? const Color(0xFF00E676).withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _poseMatched
                                ? Icons.check_circle_rounded
                                : Icons.center_focus_strong_rounded,
                            size: 16,
                            color: _poseMatched
                                ? const Color(0xFF00E676)
                                : const Color(0xFFE8B04A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _capturing
                                ? 'Capturing...'
                                : _poseMatched
                                ? 'Pose locked'
                                : 'Waiting for pose',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _currentShots.map((path) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(path),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  final String text;
  final bool isDark;

  const _MiniStatusPill({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF6EFE4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1F1A14),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool faceVisible;
  final double shotProgress;

  const _RingPainter({
    required this.progress,
    required this.faceVisible,
    required this.shotProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = (faceVisible ? const Color(0xFFCA8A04) : Colors.white)
          .withValues(alpha: 0.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width,
        height: size.height * 1.15,
      ),
      basePaint,
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = faceVisible ? const Color(0xFFCA8A04) : const Color(0xFF00E5FF);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      progress * 2 * math.pi,
      math.pi * 0.55,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      progress * 2 * math.pi + math.pi,
      math.pi * 0.55,
      false,
      arcPaint,
    );

    if (shotProgress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF00E676);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 4),
        -math.pi / 2,
        shotProgress * 2 * math.pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.faceVisible != faceVisible ||
      old.shotProgress != shotProgress;
}
