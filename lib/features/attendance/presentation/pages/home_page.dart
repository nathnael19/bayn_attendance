import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../../injection_container.dart' as di;
import '../cubit/attendance_cubit.dart';
import '../utils/camera_vision_utils.dart';
import 'attendance_page.dart';
import 'home/widgets/home_page_sections.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final bool enableAutoAttendanceRedirect;

  const HomePage({super.key, this.enableAutoAttendanceRedirect = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late AnimationController _entryController;

  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  late final FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: false,
        enableLandmarks: false,
        enableClassification: false,
      ),
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _entryController.dispose();

    _cameraController
        ?.stopImageStream()
        .then((_) {
          try {
            _cameraController?.dispose();
          } catch (_) {}
        })
        .catchError((_) {
          try {
            _cameraController?.dispose();
          } catch (_) {}
        });
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final front = CameraVisionUtils.selectFrontCamera(_cameras!);
        if (front == null) return;
        _cameraController = CameraController(
          front,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
        );
        await _cameraController!.initialize();
        if (!mounted) return;
        _cameraController!.startImageStream(_processFrame);
      }
    } catch (e) {
      debugPrint('Home Camera init error: $e');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDetecting || _isNavigating) return;
    _isDetecting = true;
    try {
      final camera = CameraVisionUtils.selectFrontCamera(_cameras!);
      if (camera == null) return;
      final inputImage = CameraVisionUtils.createInputImage(image, camera);

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      if (widget.enableAutoAttendanceRedirect &&
          faces.isNotEmpty &&
          !_isNavigating) {
        _goToAttendance();
      }
    } catch (e) {
      debugPrint('Home Face detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _goToAttendance() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;

    if (!mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => BlocProvider(
          create: (_) => di.sl<AttendanceCubit>(),
          child: const AttendancePage(),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    if (mounted) {
      _isNavigating = false;
      _initializeCamera();
    }
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = isDark
        ? const Color(0xFF07070C)
        : const Color(0xFFF7F2E8);

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Stack(
        children: [
          HomeBackground(
            animation: _bgController,
            scaffoldColor: scaffoldColor,
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      HomeTopBar(
                        pulseAnimation: _pulseController,
                        onSettings: _openSettings,
                      ),
                      const SizedBox(height: 48),
                      HomeHeroSection(pulseAnimation: _pulseController),
                      const SizedBox(height: 40),
                      const HomeStatsRow(),
                      const Spacer(),
                      HomeScanButton(
                        pulseAnimation: _pulseController,
                        onTap: _goToAttendance,
                      ),
                      const SizedBox(height: 20),
                      const HomeBottomNote(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
