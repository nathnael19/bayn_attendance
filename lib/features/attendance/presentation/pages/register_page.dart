import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../cubit/register_cubit.dart';
import '../cubit/register_state.dart';

// ─────────────────────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────────────────────

enum FaceAngle { front, left, right, up, down }

extension FaceAngleX on FaceAngle {
  String get label {
    switch (this) {
      case FaceAngle.front:
        return 'Look straight';
      case FaceAngle.left:
        return 'Turn left';
      case FaceAngle.right:
        return 'Turn right';
      case FaceAngle.up:
        return 'Tilt up';
      case FaceAngle.down:
        return 'Tilt down';
    }
  }

  IconData get icon {
    switch (this) {
      case FaceAngle.front:
        return Icons.face_rounded;
      case FaceAngle.left:
        return Icons.arrow_back_rounded;
      case FaceAngle.right:
        return Icons.arrow_forward_rounded;
      case FaceAngle.up:
        return Icons.arrow_upward_rounded;
      case FaceAngle.down:
        return Icons.arrow_downward_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  Register Page
// ─────────────────────────────────────────────────────────────

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  // Steps: 0 = form, 1 = photo capture, 2 = done
  int _step = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _departmentController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _idController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _goToCapture() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  void _onCaptureComplete(Map<FaceAngle, List<String>> shots) {
    // Convert enum keys to strings for the domain layer
    final stringKeyed = shots.map(
      (angle, paths) => MapEntry(angle.name, paths),
    );
    context.read<RegisterCubit>().submit(
      name: _nameController.text.trim(),
      employeeId: _idController.text.trim(),
      department: _departmentController.text.trim(),
      faceImagePaths: stringKeyed,
    );
  }

  void _reset() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _idController.clear();
    _departmentController.clear();
    setState(() => _step = 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF07070C) : const Color(0xFFF7F2E8),
      appBar: _step < 2
          ? AppBar(
              title: Text(_step == 0 ? 'Register Person' : 'Capture Photos'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: _step == 1
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => setState(() => _step = 0),
                    )
                  : null,
            )
          : null,
      body: BlocConsumer<RegisterCubit, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            setState(() => _step = 2);
          } else if (state is RegisterFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Save failed: ${state.message}'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
            // Still move to done — local save succeeded even if remote failed
            setState(() => _step = 2);
          }
        },
        builder: (context, state) {
          final isLoading = state is RegisterLoading;
          return Stack(
            children: [
              AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _step == 0
                        ? _FormStep(
                            key: const ValueKey('form'),
                            formKey: _formKey,
                            nameController: _nameController,
                            idController: _idController,
                            departmentController: _departmentController,
                            fadeAnim: _fadeAnim,
                            slideAnim: _slideAnim,
                            onNext: _goToCapture,
                          )
                        : _step == 1
                            ? _CaptureStep(
                                key: const ValueKey('capture'),
                                personName: _nameController.text.trim(),
                                onComplete: _onCaptureComplete,
                              )
                            : _DoneStep(
                                key: const ValueKey('done'),
                                name: _nameController.text.trim(),
                                onRegisterAnother: _reset,
                              ),
              ),
              // Full-screen loading overlay while saving
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFFCA8A04),
                            strokeWidth: 2.5,
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Saving…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Step 1 — Form
// ─────────────────────────────────────────────────────────────

class _FormStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController idController;
  final TextEditingController departmentController;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final VoidCallback onNext;

  const _FormStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.idController,
    required this.departmentController,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.9);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : const Color(0xFFE5D8C5);

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFCA8A04).withValues(alpha: 0.12),
                      const Color(0xFF00E5FF).withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFCA8A04).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: Color(0xFFCA8A04),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add a new person',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F1A14),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in the details, then we\'ll capture photos from all angles.',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : const Color(0xFF1F1A14)
                                      .withValues(alpha: 0.55),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(text: 'Full Name', isDark: isDark),
                      const SizedBox(height: 8),
                      _FormField(
                        controller: nameController,
                        hint: 'e.g. Abebe Girma',
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter the full name'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(
                          text: 'Employee / Student ID', isDark: isDark),
                      const SizedBox(height: 8),
                      _FormField(
                        controller: idController,
                        hint: 'e.g. EMP-00142',
                        icon: Icons.badge_outlined,
                        isDark: isDark,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter an ID'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(text: 'Department', isDark: isDark),
                      const SizedBox(height: 8),
                      _FormField(
                        controller: departmentController,
                        hint: 'e.g. Engineering',
                        icon: Icons.business_outlined,
                        isDark: isDark,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a department'
                            : null,
                      ),
                      const SizedBox(height: 32),

                      // Next button
                      GestureDetector(
                        onTap: onNext,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFCA8A04), Color(0xFFD97706)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFCA8A04)
                                    .withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to Photo Capture',
                                style: TextStyle(
                                  color: Color(0xFF1C1917),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Color(0xFF1C1917), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'After registering, this person can be scanned for attendance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFF1F1A14).withValues(alpha: 0.4),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Step 2 — Multi-angle capture
// ─────────────────────────────────────────────────────────────

class _CaptureStep extends StatefulWidget {
  final String personName;
  final void Function(Map<FaceAngle, List<String>> shots) onComplete;

  const _CaptureStep({
    super.key,
    required this.personName,
    required this.onComplete,
  });

  @override
  State<_CaptureStep> createState() => _CaptureStepState();
}

class _CaptureStepState extends State<_CaptureStep>
    with TickerProviderStateMixin {
  // Camera
  CameraController? _cameraController;
  bool _cameraReady = false;

  // Face detection
  late final FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _faceVisible = false;

  // Capture state
  final _angles = FaceAngle.values;
  int _angleIndex = 0;

  /// path lists per angle
  final Map<FaceAngle, List<String>> _shots = {
    for (final a in FaceAngle.values) a: [],
  };

  static const int _shotsPerAngle = 3;
  bool _capturing = false;

  // Animations
  late AnimationController _ringController;
  late AnimationController _flashController;
  late Animation<double> _flashAnim;

  FaceAngle get _currentAngle => _angles[_angleIndex];
  List<String> get _currentShots => _shots[_currentAngle]!;

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashAnim =
        CurvedAnimation(parent: _flashController, curve: Curves.easeOut);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
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
      final WriteBuffer buf = WriteBuffer();
      for (final p in image.planes) {
        buf.putUint8List(p.bytes);
      }
      final bytes = buf.done().buffer.asUint8List();

      final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
          (defaultTargetPlatform == TargetPlatform.iOS
              ? InputImageFormat.bgra8888
              : InputImageFormat.nv21);

      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final rotation =
          InputImageRotationValue.fromRawValue(front.sensorOrientation) ??
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
      if (hasFace != _faceVisible) {
        setState(() => _faceVisible = hasFace);
      }
    } catch (_) {
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _captureShot() async {
    if (!_cameraReady ||
        _cameraController == null ||
        !_faceVisible ||
        _capturing) { return; }

    setState(() => _capturing = true);

    // Flash effect
    _flashController.forward(from: 0);

    try {
      // Stop stream, take picture, restart stream
      await _cameraController!.stopImageStream();
      final xFile = await _cameraController!.takePicture();
      await _cameraController!.startImageStream(_processFrame);

      if (!mounted) return;
      setState(() {
        _currentShots.add(xFile.path);
        _capturing = false;
      });

      // Auto-advance to next angle when enough shots collected
      if (_currentShots.length >= _shotsPerAngle) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        if (_angleIndex < _angles.length - 1) {
          setState(() => _angleIndex++);
        } else {
          // All angles done
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
    final totalDone =
        _shots.values.fold(0, (sum, list) => sum + list.length);
    final totalNeeded = _angles.length * _shotsPerAngle;
    final progress = totalDone / totalNeeded;

    return Column(
      children: [
        // ── Progress bar
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.personName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$totalDone / $totalNeeded photos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFCA8A04)),
                ),
              ),
            ],
          ),
        ),

        // ── Angle chips
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF00E676).withValues(alpha: 0.15)
                      : active
                          ? const Color(0xFFCA8A04).withValues(alpha: 0.15)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
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
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
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
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // ── Camera + overlay
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
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

              // Dark vignette
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

              // Scan ring
              Center(
                child: AnimatedBuilder(
                  animation: _ringController,
                  builder: (_, child) {
                    return CustomPaint(
                      size: const Size(230, 230),
                      painter: _RingPainter(
                        progress: _ringController.value,
                        faceVisible: _faceVisible,
                        shotProgress:
                            _currentShots.length / _shotsPerAngle,
                      ),
                    );
                  },
                ),
              ),

              // Flash overlay
              FadeTransition(
                opacity: _flashAnim.drive(
                  Tween(begin: 0.0, end: 0.6).chain(
                    CurveTween(curve: const Interval(0, 0.4)),
                  ),
                ),
                child: Container(color: Colors.white),
              ),

              // Instruction banner
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // Shot dots
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

                    // Instruction pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _faceVisible
                              ? const Color(0xFFCA8A04).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _currentAngle.label,
                            style: const TextStyle(
                              color: Color(0xFFCA8A04),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _faceVisible
                                ? 'Tap the button to take a photo'
                                : 'Position your face in the circle',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Capture button
                    GestureDetector(
                      onTap: _captureShot,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _faceVisible && !_capturing
                              ? const Color(0xFFCA8A04)
                              : Colors.white.withValues(alpha: 0.15),
                          boxShadow: _faceVisible && !_capturing
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFCA8A04)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: _capturing
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFF1C1917),
                                size: 28,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Thumbnail strip (top-right)
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

// ─────────────────────────────────────────────────────────────
//  Step 3 — Done
// ─────────────────────────────────────────────────────────────

class _DoneStep extends StatelessWidget {
  final String name;
  final VoidCallback onRegisterAnother;

  const _DoneStep({
    super.key,
    required this.name,
    required this.onRegisterAnother,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00E676),
                size: 46,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '$name is registered!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F1A14),
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'All face angles have been captured. They\'re ready to be scanned for attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : const Color(0xFF1F1A14).withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCA8A04), Color(0xFFD97706)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCA8A04).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Back to Settings',
                    style: TextStyle(
                      color: Color(0xFF1C1917),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRegisterAnother,
              child: const Text(
                'Register another person',
                style: TextStyle(color: Color(0xFFCA8A04)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Ring painter
// ─────────────────────────────────────────────────────────────

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

    // Base oval guide
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = (faceVisible ? const Color(0xFFCA8A04) : Colors.white)
          .withValues(alpha: 0.25);
    canvas.drawOval(Rect.fromCenter(center: center, width: size.width, height: size.height * 1.15), basePaint);

    // Rotating arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color =
          faceVisible ? const Color(0xFFCA8A04) : const Color(0xFF00E5FF);

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

    // Shot-progress arc (gold fill from top)
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

// ─────────────────────────────────────────────────────────────
//  Shared form widgets
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const _SectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.6)
            : const Color(0xFF1F1A14).withValues(alpha: 0.65),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1F1A14),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.25)
              : const Color(0xFF1F1A14).withValues(alpha: 0.35),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFCA8A04), size: 20),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5D8C5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5D8C5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFCA8A04), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
