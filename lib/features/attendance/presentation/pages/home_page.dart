import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/home_stats_cubit.dart';
import '../cubit/home_stats_state.dart';
import '../../../../injection_container.dart' as di;
import 'attendance_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late AnimationController _entryController;

  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

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
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _goToAttendance() {
    Navigator.of(context).push(
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
          // Animated gradient orbs background
          _buildBackground(),

          // Content
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
                      _buildTopBar(),
                      const SizedBox(height: 48),
                      _buildHeroSection(),
                      const SizedBox(height: 40),
                      _buildStatsRow(),
                      const Spacer(),
                      _buildScanButton(),
                      const SizedBox(height: 20),
                      _buildBottomNote(),
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

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) {
        final t = _bgController.value;
        return Stack(
          children: [
            // Top-right gold orb
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFCA8A04).withValues(
                        alpha: 0.12 + 0.05 * math.sin(t * 2 * math.pi),
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom-left cyan orb
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00E5FF).withValues(
                        alpha: 0.07 + 0.03 * math.cos(t * 2 * math.pi),
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle grid
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          ],
        );
      },
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F1A14);
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFF1F1A14).withValues(alpha: 0.55);

    return Row(
      children: [
        // Logo
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Text(
                'BAYN',
                style: TextStyle(
                  color: Color.lerp(
                    const Color(0xFFCA8A04),
                    const Color(0xFFFFD700),
                    _pulseController.value,
                  ),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                ),
              ),
            ),
            Text(
              'Attendance System',
              style: TextStyle(
                color: mutedColor,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Date chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFFCA8A04),
                size: 13,
              ),
              const SizedBox(width: 7),
              Text(
                _formattedDate(),
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Settings icon
        IconButton(
          onPressed: _openSettings,
          icon: Icon(
            Icons.settings_rounded,
            color: titleColor.withValues(alpha: 0.75),
          ),
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F1A14);
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFF1F1A14).withValues(alpha: 0.68);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Opacity(
                  opacity: _pulseController.value,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SYSTEM READY',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Mark your\nattendance',
          style: TextStyle(
            color: titleColor,
            fontSize: 42,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Look into the camera and we\'ll handle the rest.\nFace recognition takes just a few seconds.',
          style: TextStyle(color: bodyColor, fontSize: 15, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return BlocBuilder<HomeStatsCubit, HomeStatsState>(
      builder: (context, state) {
        String total = '-';
        String accuracy = '-';
        String speed = '-';

        if (state is HomeStatsLoaded) {
          total = state.stats.totalCheckedIn.toString();
          accuracy = state.stats.accuracyLabel;
          speed = state.stats.scanTimeLabel;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.82);
        final borderColor = isDark
            ? Colors.white.withValues(alpha: 0.07)
            : const Color(0xFFE5D8C5);

        return Row(
          children: [
            _StatCard(
              label: 'Today',
              value: total,
              subtitle: 'checked in',
              color: const Color(0xFF00E676),
              cardColor: cardColor,
              borderColor: borderColor,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Accuracy',
              value: accuracy,
              subtitle: 'recognition',
              color: const Color(0xFF00E5FF),
              cardColor: cardColor,
              borderColor: borderColor,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Speed',
              value: speed,
              subtitle: 'avg scan time',
              color: const Color(0xFFCA8A04),
              cardColor: cardColor,
              borderColor: borderColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: _goToAttendance,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) {
          return Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFCA8A04), Color(0xFFD97706)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFCA8A04,
                  ).withValues(alpha: 0.3 + 0.15 * _pulseController.value),
                  blurRadius: 24 + 8 * _pulseController.value,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural_rounded,
                    color: Color(0xFF1C1917),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Start Face Scan',
                  style: TextStyle(
                    color: Color(0xFF1C1917),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF1C1917),
                  size: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNote() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        'Your biometric data is processed on-device and never stored.',
        style: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : const Color(0xFF1F1A14).withValues(alpha: 0.45),
          fontSize: 12,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final Color cardColor;
  final Color borderColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.35)
                    : const Color(0xFF1F1A14).withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFF1F1A14).withValues(alpha: 0.38),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle grid background painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
