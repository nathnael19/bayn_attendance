import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../utils/camera_vision_utils.dart';
import 'attendance/widgets/attendance_page_sections.dart';

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
        final front = CameraVisionUtils.selectFrontCamera(_cameras!);
        if (front == null) return;
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
    if (cubitState is AttendanceSuccess || cubitState is AttendanceFailure)
      return;

    _isDetecting = true;
    try {
      final camera = CameraVisionUtils.selectFrontCamera(_cameras!);
      if (camera == null) return;
      final inputImage = CameraVisionUtils.createInputImage(image, camera);

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

  Future<void> _captureAndRecognize() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    try {
      await _cameraController!.stopImageStream();
      final xFile = await _cameraController!.takePicture();

      await _cameraController!.startImageStream(_processFrame);

      if (!mounted) return;
      await context.read<AttendanceCubit>().recognizeFace(xFile.path);
    } catch (e) {
      debugPrint('Capture error: $e');
      try {
        if (_cameraController != null) {
          await _cameraController!.startImageStream(_processFrame);
        }
      } catch (_) {}

      if (mounted) {
        context.read<AttendanceCubit>().startScanning();
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _cameraController
        ?.stopImageStream()
        .then((_) {
          _cameraController?.dispose();
        })
        .catchError((_) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = isDark
        ? const Color(0xFF0A0A0E)
        : const Color(0xFFF7F2E8);

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: BlocConsumer<AttendanceCubit, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceScanning) {
            _captureAndRecognize();
          } else if (state is AttendanceSuccess) {
            _speak('Attendance marked successfully.');
            _onSuccess();
          } else if (state is AttendanceFailure) {
            _speak('Failed to register attendance. Please try again.');
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              AttendanceBackground(
                isCameraInitialized: _isCameraInitialized,
                cameraController: _cameraController,
                scaffoldColor: scaffoldColor,
              ),
              AttendanceParticles(animation: _particleController),
              SafeArea(
                child: Column(
                  children: [
                    AttendanceHeader(
                      state: state,
                      faceVisible: _faceVisible,
                      headerGlowAnimation: _headerGlowAnimation,
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: AttendanceScanArea(
                        state: state,
                        faceVisible: _faceVisible,
                      ),
                    ),
                    AttendanceStatusCard(
                      context: context,
                      state: state,
                      faceVisible: _faceVisible,
                      onRetry: () =>
                          context.read<AttendanceCubit>().startScanning(),
                    ),
                  ],
                ),
              ),
              if (state is AttendanceInitial && !_faceVisible)
                AttendanceFaceHint(animation: _headerGlowAnimation),
            ],
          );
        },
      ),
    );
  }
}
