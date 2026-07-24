import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/register_cubit.dart';
import '../cubit/register_state.dart';
import 'register/models/register_face_angle.dart';
import 'register/widgets/register_capture_step.dart';
import 'register/widgets/register_done_step.dart';
import 'register/widgets/register_form_step.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  int _step = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

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
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _idController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _goToCapture() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  void _onCaptureComplete(Map<FaceAngle, List<String>> shots) {
    final stringKeyed = shots.map(
      (angle, paths) => MapEntry(angle.name, paths),
    );
    context.read<RegisterCubit>().submit(
      name: _nameController.text.trim(),
      employeeId: _idController.text.trim(),
      department: _departmentController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      faceImagePaths: stringKeyed,
    );
  }

  void _reset() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _idController.clear();
    _departmentController.clear();
    _phoneController.clear();
    _emailController.clear();
    setState(() => _step = 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF06070B)
          : const Color(0xFFF4F1EA),
      appBar: _step < 2
          ? AppBar(
              title: Text(_step == 0 ? 'Identity setup' : 'Face verification'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            setState(() => _step = 2);
          }
        },
        builder: (context, state) {
          final showOverlay =
              state is RegisterProcessingEmbeddings || state is RegisterLoading;

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.85),
                      radius: 1.35,
                      colors: [
                        const Color(
                          0xFFCA8A04,
                        ).withValues(alpha: isDark ? 0.08 : 0.11),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _step == 0
                    ? RegisterFormStep(
                        key: const ValueKey('form'),
                        formKey: _formKey,
                        nameController: _nameController,
                        idController: _idController,
                        departmentController: _departmentController,
                        phoneController: _phoneController,
                        emailController: _emailController,
                        fadeAnim: _fadeAnim,
                        slideAnim: _slideAnim,
                        onNext: _goToCapture,
                      )
                    : _step == 1
                    ? RegisterCaptureStep(
                        key: const ValueKey('capture'),
                        personName: _nameController.text.trim(),
                        onComplete: _onCaptureComplete,
                      )
                    : RegisterDoneStep(
                        key: const ValueKey('done'),
                        name: _nameController.text.trim(),
                        onRegisterAnother: _reset,
                      ),
              ),
              if (showOverlay)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: state is RegisterProcessingEmbeddings
                          ? _ProcessingProgress(
                              current: state.current,
                              total: state.total,
                              progress: state.progress,
                            )
                          : const Column(
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

class _ProcessingProgress extends StatelessWidget {
  final int current;
  final int total;
  final double progress;

  const _ProcessingProgress({
    required this.current,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: progress,
              color: const Color(0xFFCA8A04),
              strokeWidth: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Generating face embeddings…',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$current of $total processed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFCA8A04)),
            ),
          ),
        ],
      ),
    );
  }
}
