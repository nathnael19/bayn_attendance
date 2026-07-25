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
import '../../../auth/presentation/pages/admin_login_page.dart';

class HomePage extends StatefulWidget {
  final bool enableAutoAttendanceRedirect;

  const HomePage({super.key, this.enableAutoAttendanceRedirect = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  late final FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _isNavigating = false;

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
    _initializeCamera();
  }

  @override
  void dispose() {
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
    if (_isDetecting || _isNavigating || _cameras == null) return;
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
        pageBuilder: (_, animation, _) => BlocProvider(
          create: (_) => di.sl<AttendanceCubit>(),
          child: const AttendancePage(),
        ),
        transitionsBuilder: (_, animation, _, child) {
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
    ).push(MaterialPageRoute(builder: (_) => const AdminLoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              HomeTopBar(onSettings: _openSettings),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 58, bottom: 32),
                  child: HomeHeroSection(onTap: _goToAttendance),
                ),
              ),
              const HomeBottomNote(),
            ],
          ),
        ),
      ),
    );
  }
}
