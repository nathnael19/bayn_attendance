import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubit/home_stats_cubit.dart';
import '../../../cubit/home_stats_state.dart';

class HomeBackground extends StatelessWidget {
  final Animation<double> animation;
  final Color scaffoldColor;

  const HomeBackground({
    super.key,
    required this.animation,
    required this.scaffoldColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        return Stack(
          children: [
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
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          ],
        );
      },
    );
  }
}

class HomeTopBar extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final VoidCallback onSettings;

  const HomeTopBar({
    super.key,
    required this.pulseAnimation,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F1A14);
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFF1F1A14).withValues(alpha: 0.55);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) => Text(
                'BAYN',
                style: TextStyle(
                  color: Color.lerp(
                    const Color(0xFFCA8A04),
                    const Color(0xFFFFD700),
                    pulseAnimation.value,
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
        IconButton(
          onPressed: onSettings,
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
}

class HomeHeroSection extends StatelessWidget {
  final Animation<double> pulseAnimation;

  const HomeHeroSection({super.key, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F1A14);
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFF1F1A14).withValues(alpha: 0.68);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                animation: pulseAnimation,
                builder: (_, __) => Opacity(
                  opacity: pulseAnimation.value,
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
}

class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
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
}

class HomeScanButton extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const HomeScanButton({
    super.key,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseAnimation,
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
                  ).withValues(alpha: 0.3 + 0.15 * pulseAnimation.value),
                  blurRadius: 24 + 8 * pulseAnimation.value,
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
}

class HomeBottomNote extends StatelessWidget {
  const HomeBottomNote({super.key});

  @override
  Widget build(BuildContext context) {
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
