import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../widgets/biometric_scan_frame.dart';
import '../widgets/attendance_status_panel.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // ML Kit face detector
  late final FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _faceVisible = false;

  // Text-to-speech
  final FlutterTts _tts = FlutterTts();

  // Header glow animation
  late AnimationController _headerGlowController;
  late Animation<double> _headerGlowAnimation;

  // Particle system
  late AnimationController _particleController;

  // Success exit animation
  late AnimationController _successController;
  bool _navigatingBack = false;

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: false,
        enableLandmarks: false,
        enableClassification: false,
      ),
    );

    _initializeTts();
    _initializeCamera();

    _headerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _headerGlowAnimation = CurvedAnimation(
      parent: _headerGlowController,
      curve: Curves.easeInOut,
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String message) async {
    await _tts.stop();
    await _tts.speak(message);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final front = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        _cameraController = CameraController(
          front,
          ResolutionPreset.medium,
          enableAudio: false,
          // Let the platform pick the right format automatically
          imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
        );
        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() => _isCameraInitialized = true);

        // Start streaming frames for face detection
        _cameraController!.startImageStream(_processFrame);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDetecting) return;
    final cubitState = context.read<AttendanceCubit>().state;
    // Stop processing once we have a result
    if (cubitState is AttendanceSuccess || cubitState is AttendanceFailure) return;

    _isDetecting = true;
    try {
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Use WriteBuffer — much faster than List<int> for large image data
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Detect format from the actual image, don't hardcode
      final format = InputImageFormatValue.fromRawValue(image.format.raw)
          ?? (defaultTargetPlatform == TargetPlatform.iOS
              ? InputImageFormat.bgra8888
              : InputImageFormat.nv21);

      // Detect rotation from sensor — ML Kit handles the rest
      final rotation = InputImageRotationValue.fromRawValue(
              camera.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      final hasFace = faces.isNotEmpty;

      // Update face-visible indicator regardless
      if (hasFace != _faceVisible) {
        setState(() => _faceVisible = hasFace);
      }

      // Only act on face detected/lost when we are in initial (waiting) state.
      // Once scanning has started, let it finish — don't cancel on a missed frame.
      final currentState = context.read<AttendanceCubit>().state;
      if (currentState is AttendanceInitial) {
        if (hasFace) {
          context.read<AttendanceCubit>().onFaceDetected();
        }
        // Don't call onFaceLost here — initial is already waiting state
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _onSuccess() {
    if (_navigatingBack) return;
    _navigatingBack = true;

    // Wait 2 seconds on success screen then navigate back to home
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _cameraController?.stopImageStream().then((_) {
      _cameraController?.dispose();
    }).catchError((_) {
      _cameraController?.dispose();
    });
    _faceDetector.close();
    _headerGlowController.dispose();
    _particleController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      body: BlocConsumer<AttendanceCubit, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceSuccess) {
            _speak('Attendance marked successfully.');
            _onSuccess();
          } else if (state is AttendanceFailure) {
            _speak('Failed to register attendance. Please try again.');
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              _buildBackground(),
              _buildParticles(),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(state),
                    Expanded(child: _buildScanArea(state)),
                    _buildStatusCard(context, state),
                  ],
                ),
              ),

              // Face detection hint overlay (only in initial state with no face)
              if (state is AttendanceInitial && !_faceVisible)
                _buildFaceHint(),
            ],
          );
        },
      ),
    );
  }

  // ── Face hint overlay ─────────────────────────────────────
  Widget _buildFaceHint() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Center(
            child: AnimatedBuilder(
              animation: _headerGlowAnimation,
              builder: (_, __) => Opacity(
                opacity: 0.5 + 0.5 * _headerGlowAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
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

  // ── Background ────────────────────────────────────────────
  Widget _buildBackground() {
    return Stack(
      children: [
        if (_isCameraInitialized && _cameraController != null)
          Positioned.fill(child: CameraPreview(_cameraController!))
        else
          Positioned.fill(
              child: Container(color: const Color(0xFF0A0A0E))),

        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  const Color(0xFF0A0A0E).withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top: 0, left: 0, right: 0, height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF0A0A0E), Colors.transparent],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0, left: 0, right: 0, height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [const Color(0xFF0A0A0E), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Particles ─────────────────────────────────────────────
  Widget _buildParticles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (_, __) => CustomPaint(
          painter: _ParticlePainter(_particleController.value),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(AttendanceState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _headerGlowAnimation,
                builder: (_, __) => Text(
                  'BAYN',
                  style: TextStyle(
                    color: Color.lerp(
                      const Color(0xFFCA8A04),
                      const Color(0xFFFFD700),
                      _headerGlowAnimation.value,
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
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          const Spacer(),
          _LiveIndicator(state: state, faceVisible: _faceVisible),
        ],
      ),
    );
  }

  // ── Scan area ─────────────────────────────────────────────
  Widget _buildScanArea(AttendanceState state) {
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
                        : _faceVisible
                            ? 'FACE DETECTED'
                            : 'WAITING',
            color: state is AttendanceSuccess
                ? const Color(0xFF00E676)
                : state is AttendanceFailure
                    ? const Color(0xFFFF1744)
                    : _faceVisible
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF00E5FF).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 28),
          BiometricScanFrame(state: state),
          const SizedBox(height: 28),
          if (state is AttendanceScanning || state is AttendanceInitial)
            _AlignmentGuide(active: _faceVisible),
        ],
      ),
    );
  }

  // ── Status card ───────────────────────────────────────────
  Widget _buildStatusCard(BuildContext context, AttendanceState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AttendanceStatusPanel(
          state: state,
          faceVisible: _faceVisible,
          onRetry: () => context.read<AttendanceCubit>().startScanning(),
        ),
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────

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
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
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
                    : Colors.white.withValues(alpha: 0.3);

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
                        color: color.withValues(alpha: 0.6), blurRadius: 4)
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
              color: const Color(0xFF00E5FF)
                  .withValues(alpha: isCenter ? 0.6 : 0.2),
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
        final flicker =
            _controller.value > 0.92 && _controller.value < 0.95 ? 0.4 : 1.0;
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
          child: Opacity(
            opacity: flicker,
            child: Text(widget.text),
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
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

  const _ParticlePainter(this.t);

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
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _Particle {
  final double x, y, speed, size, opacity;
  const _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}
