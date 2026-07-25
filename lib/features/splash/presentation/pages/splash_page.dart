import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  final Future<void> Function()? onInitialize;
  final WidgetBuilder destinationBuilder;
  final Duration minimumDisplayDuration;

  const SplashPage({
    super.key,
    required this.destinationBuilder,
    this.onInitialize,
    this.minimumDisplayDuration = const Duration(milliseconds: 2500),
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;
  bool _reducedMotion = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    
    // Remove native splash screen when Flutter splash is shown
    FlutterNativeSplash.remove();
    
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (_reducedMotion) {
        _introController.value = 1;
        _pulseController.value = 0.65;
      } else {
        _introController.forward();
        _pulseController.repeat(reverse: true);
      }
      setState(() {});
    });

    _completeStartup();
  }

  Future<void> _completeStartup() async {
    final minimumDuration = Future<void>.delayed(widget.minimumDisplayDuration);

    try {
      await Future.wait<void>([
        minimumDuration,
        widget.onInitialize?.call() ?? Future<void>.value(),
      ]);
    } catch (error) {
      // A splash should not trap the user if an optional cache refresh fails.
      debugPrint('[Splash] Startup refresh failed: $error');
      await minimumDuration;
    }

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => widget.destinationBuilder(context),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.homeDarkBackground : AppTheme.homeLightBackground,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: IgnorePointer(child: _StageGrid())),
            _AmbientGlow(
              alignment: Alignment(-1.2, -0.45),
              color: AppTheme.homeSky,
            ),
            _AmbientGlow(
              alignment: Alignment(1.2, 0.72),
              color: AppTheme.homeGold,
            ),
            Column(
              children: [
                _SplashHeader(isDark: isDark),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(28, 12, 28, 26),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(
                              0.0,
                              constraints.maxHeight - 38,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SystemHeading(isDark: isDark),
                              const SizedBox(height: 26),
                              _ProcessingVisual(
                                introAnimation: _introController,
                                pulseAnimation: _pulseController,
                                reducedMotion: _reducedMotion,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 14),
                              _LoadingPulse(isDark: isDark),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _SplashFooter(isDark: isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashHeader extends StatelessWidget {
  final bool isDark;

  const _SplashHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.homeDarkText : AppTheme.homeLightText;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BAYN ATTENDANCE',
                style: _monoStyle(
                  color: textColor.withValues(alpha: 0.72),
                  fontSize: 10,
                  letterSpacing: 3.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(width: 48, height: 1, color: AppTheme.homeGold),
            ],
          ),
          Row(
            children: [
              _StatusDot(isDark: isDark),
              const SizedBox(width: 8),
              Text(
                'LOCAL / 01',
                style: _monoStyle(
                  color: textColor.withValues(alpha: 0.38),
                  fontSize: 9,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplashFooter extends StatelessWidget {
  final bool isDark;

  const _SplashFooter({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.homeDarkText : AppTheme.homeLightText;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SECURE / PRIVATE / LOCAL',
            style: _monoStyle(
              color: textColor.withValues(alpha: 0.3),
              fontSize: 8,
              letterSpacing: 1.8,
            ),
          ),
          Text(
            'V1.0.0',
            style: _monoStyle(
              color: textColor.withValues(alpha: 0.3),
              fontSize: 8,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemHeading extends StatelessWidget {
  final bool isDark;

  const _SystemHeading({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.homeDarkText : AppTheme.homeLightText;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DividerLine(isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'PRESENCE / SYSTEM',
            style: _monoStyle(
              color: textColor.withValues(alpha: 0.36),
              fontSize: 9,
              letterSpacing: 2.4,
            ),
          ),
        ),
        _DividerLine(isDark: isDark),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  final bool isDark;

  const _DividerLine({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.homeDarkText : AppTheme.homeLightText;
    
    return Container(
      width: 32,
      height: 1,
      color: textColor.withValues(alpha: 0.18),
    );
  }
}

class _ProcessingVisual extends StatelessWidget {
  final Animation<double> introAnimation;
  final Animation<double> pulseAnimation;
  final bool reducedMotion;
  final bool isDark;

  const _ProcessingVisual({
    required this.introAnimation,
    required this.pulseAnimation,
    required this.reducedMotion,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([introAnimation, pulseAnimation]),
        builder: (context, _) {
          final orbReveal = _intervalValue(introAnimation.value, 0.05, 0.4);
          final ringReveal = _intervalValue(introAnimation.value, 0.18, 0.52);
          final scanReveal = _intervalValue(introAnimation.value, 0.74, 0.98);
          final glowPulse = reducedMotion
              ? 0.65
              : 0.82 + (pulseAnimation.value * 0.18);

          return SizedBox(
            height: 350,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ProcessingPainter(
                      orbReveal: orbReveal,
                      ringReveal: ringReveal,
                      scanReveal: scanReveal,
                      pulse: glowPulse,
                      isDark: isDark,
                    ),
                  ),
                ),
                Positioned(
                  left: 40,
                  top:
                      58 +
                      ((1 - _intervalValue(introAnimation.value, 0.2, 0.56)) *
                          92),
                  child: Opacity(
                    opacity: _intervalValue(introAnimation.value, 0.2, 0.56),
                    child: Transform.rotate(
                      angle: -8 * math.pi / 180,
                      child: const _GlassRecordPanel(
                        height: 104,
                        width: 252,
                        label: 'ENTRY 001',
                        title: 'Morning shift',
                        badge: 'IN',
                        badgeColor: AppTheme.homeGold,
                        timestamp: '08:42:16',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 29,
                  top:
                      128 +
                      ((1 - _intervalValue(introAnimation.value, 0.32, 0.68)) *
                          92),
                  child: Opacity(
                    opacity: _intervalValue(introAnimation.value, 0.32, 0.68),
                    child: Transform.rotate(
                      angle: 3 * math.pi / 180,
                      child: const _GlassRecordPanel(
                        height: 98,
                        width: 242,
                        label: 'VERIFYING',
                        title: 'Identity matched',
                        badge: '98%',
                        badgeColor: AppTheme.homeSky,
                        timestamp: 'MATCH / 98.4%',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 48,
                  top:
                      198 +
                      ((1 - _intervalValue(introAnimation.value, 0.44, 0.8)) *
                          92),
                  child: Opacity(
                    opacity: _intervalValue(introAnimation.value, 0.44, 0.8),
                    child: Transform.rotate(
                      angle: -4 * math.pi / 180,
                      child: const _GlassRecordPanel(
                        height: 94,
                        width: 248,
                        label: 'DAY STATUS',
                        title: 'All accounted for',
                        badge: 'READY',
                        badgeColor: AppTheme.homeStatusGreen,
                        timestamp: 'SYNCED TO LOCAL RECORDS',
                      ),
                    ),
                  ),
                ),
                _CornerMark(
                  alignment: Alignment.topLeft,
                  visible: _intervalValue(introAnimation.value, 0.64, 0.84),
                ),
                _CornerMark(
                  alignment: Alignment.topRight,
                  visible: _intervalValue(introAnimation.value, 0.64, 0.84),
                ),
                _CornerMark(
                  alignment: Alignment.bottomLeft,
                  visible: _intervalValue(introAnimation.value, 0.64, 0.84),
                ),
                _CornerMark(
                  alignment: Alignment.bottomRight,
                  visible: _intervalValue(introAnimation.value, 0.64, 0.84),
                ),
                Positioned(
                  left: 4,
                  top: 20,
                  child: Opacity(
                    opacity: _intervalValue(introAnimation.value, 0.68, 0.86),
                    child: Text(
                      'SCAN FIELD 03',
                      style: _monoStyle(
                        color: AppTheme.homeGold.withValues(alpha: 0.65),
                        fontSize: 8,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 1,
                  child: Opacity(
                    opacity: _intervalValue(introAnimation.value, 0.68, 0.86),
                    child: Text(
                      'CAL / 24.07',
                      style: _monoStyle(
                        color: (isDark ? AppTheme.homeDarkText : AppTheme.homeLightText).withValues(alpha: 0.3),
                        fontSize: 8,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GlassRecordPanel extends StatelessWidget {
  final double height;
  final double width;
  final String label;
  final String title;
  final String badge;
  final Color badgeColor;
  final String timestamp;

  const _GlassRecordPanel({
    required this.height,
    required this.width,
    required this.label,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? AppTheme.homeDarkText : AppTheme.homeLightText;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 13, sigmaY: 13),
        child: Container(
          height: height,
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? const [Color(0x2BFFFFFF), Color(0x0CFFFFFF), Color(0x140EA5E9)]
                : const [Color(0x50FFFFFF), Color(0x3AFFFFFF), Color(0x280EA5E9)],
              stops: const [0, 0.46, 1],
            ),
            border: Border.all(
              color: isDark 
                ? const Color(0x3BFFFFFF)
                : const Color(0x50FFFFFF),
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: isDark 
                  ? const Color(0x42000000)
                  : const Color(0x15000000),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: isDark 
                  ? const Color(0x20FFFFFF)
                  : const Color(0x40FFFFFF),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: _monoStyle(
                            color: foreground.withValues(alpha: 0.52),
                            fontSize: 9,
                            letterSpacing: 1.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.atkinsonHyperlegible(
                            color: foreground,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.38),
                      ),
                    ),
                    child: Text(
                      badge,
                      style: _monoStyle(
                        color: badgeColor == AppTheme.homeStatusGreen
                            ? const Color(0xFF8FD8C3)
                            : badgeColor == AppTheme.homeSky
                            ? const Color(0xFF7DD3FC)
                            : const Color(0xFFF2C85B),
                        fontSize: 8,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Flexible(
                    flex: 0,
                    child: _RecordProgress(color: badgeColor),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      timestamp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _monoStyle(
                        color: foreground.withValues(alpha: 0.42),
                        fontSize: 8,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordProgress extends StatelessWidget {
  final Color color;

  const _RecordProgress({required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.homeDarkText : AppTheme.homeLightText;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 20,
          height: 4,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 10,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.homeSky.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }
}

class _CornerMark extends StatelessWidget {
  final Alignment alignment;
  final double visible;

  const _CornerMark({required this.alignment, required this.visible});

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Opacity(
        opacity: visible,
        child: SizedBox(
          height: 26,
          width: 26,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: isTop
                    ? BorderSide(
                        color: AppTheme.homeGold.withValues(alpha: 0.72),
                      )
                    : BorderSide.none,
                bottom: !isTop
                    ? BorderSide(
                        color: AppTheme.homeGold.withValues(alpha: 0.72),
                      )
                    : BorderSide.none,
                left: isLeft
                    ? BorderSide(
                        color: AppTheme.homeGold.withValues(alpha: 0.72),
                      )
                    : BorderSide.none,
                right: !isLeft
                    ? BorderSide(
                        color: AppTheme.homeGold.withValues(alpha: 0.72),
                      )
                    : BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPulse extends StatelessWidget {
  final bool isDark;

  const _LoadingPulse({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final textColor = isDark ? AppTheme.homeDarkText : AppTheme.homeLightText;
    
    return Column(
      children: [
        Text(
          'READYING YOUR DAY',
          style: _monoStyle(
            color: textColor.withValues(alpha: 0.72),
            fontSize: 10,
            letterSpacing: 3.2,
          ),
        ),
        const SizedBox(height: 15),
        Semantics(
          label: 'Loading attendance records',
          liveRegion: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final dot = Container(
                width: 6,
                height: 6,
                margin: EdgeInsets.only(left: index == 0 ? 0 : 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.homeGold.withValues(
                    alpha: 1 - (index * 0.32),
                  ),
                ),
              );
              if (reducedMotion) return dot;
              return dot
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scaleXY(
                    begin: 0.9,
                    end: 1.55,
                    duration: 700.ms,
                    delay: (index * 170).ms,
                    curve: Curves.easeInOut,
                  )
                  .fade(
                    begin: 0.45,
                    end: 1,
                    duration: 700.ms,
                    delay: (index * 170).ms,
                    curve: Curves.easeInOut,
                  );
            }),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool isDark;

  const _StatusDot({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.homeStatusGreen,
        boxShadow: [
          BoxShadow(
            color: AppTheme.homeStatusGreen.withValues(alpha: 0.55),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Alignment alignment;
  final Color color;

  const _AmbientGlow({required this.alignment, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 34, sigmaY: 34),
        child: Container(
          height: 300,
          width: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.09),
                color.withValues(alpha: 0.025),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageGrid extends StatelessWidget {
  const _StageGrid();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(painter: _StageGridPainter(isDark: isDark));
  }
}

class _StageGridPainter extends CustomPainter {
  final bool isDark;
  
  const _StageGridPainter({required this.isDark});
  
  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isDark ? AppTheme.homeDarkText : AppTheme.homeLightText;
    final paint = Paint()
      ..color = baseColor.withValues(alpha: isDark ? 0.07 : 0.12)
      ..style = PaintingStyle.fill;

    const step = 18.0;
    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height * 0.85; y += step) {
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StageGridPainter oldDelegate) => oldDelegate.isDark != isDark;
}

class _ProcessingPainter extends CustomPainter {
  final double orbReveal;
  final double ringReveal;
  final double scanReveal;
  final double pulse;
  final bool isDark;

  const _ProcessingPainter({
    required this.orbReveal,
    required this.ringReveal,
    required this.scanReveal,
    required this.pulse,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 198);
    final orbRadius =
        43.0 * Curves.easeOutBack.transform(orbReveal.clamp(0, 1));
    final ringAmount = Curves.easeOut.transform(ringReveal.clamp(0, 1));
    
    final baseColor = isDark ? AppTheme.homeDarkText : AppTheme.homeLightText;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.homeGold.withValues(alpha: 0.36 * pulse),
          AppTheme.homeGold.withValues(alpha: 0.12 * pulse),
          AppTheme.homeSky.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0, 0.34, 0.56, 1],
      ).createShader(Rect.fromCircle(center: center, radius: 122));
    canvas.drawCircle(center, 122, glowPaint);

    final orbPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.5),
        radius: 1.0,
        colors: const [
          Color(0xFFFFF7CF),
          Color(0xFFF2C85B),
          AppTheme.homeGold,
          Color(0xFF88631E),
          Color(0xFF262321),
        ],
        stops: [0, 0.14, 0.36, 0.64, 1],
      ).createShader(Rect.fromCircle(center: center, radius: 43));
    canvas.drawCircle(center, orbRadius, orbPaint);

    final orbHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.46 * orbReveal)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      center.translate(-orbRadius * 0.28, -orbRadius * 0.34),
      orbRadius * 0.16,
      orbHighlight,
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = baseColor.withValues(alpha: (isDark ? 0.2 : 0.3) * ringAmount)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.2);
    canvas.drawCircle(center, 85 * ringAmount, ringPaint);

    final dashedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.homeSky.withValues(alpha: (isDark ? 0.28 : 0.4) * ringAmount);
    _drawDashedCircle(canvas, center, 69 * ringAmount, dashedPaint);

    final crosshairPaint = Paint()
      ..color = baseColor.withValues(alpha: (isDark ? 0.38 : 0.45) * ringAmount)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - 120 * ringAmount, center.dy),
      Offset(center.dx + 120 * ringAmount, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 120 * ringAmount),
      Offset(center.dx, center.dy + 120 * ringAmount),
      crosshairPaint,
    );

    final scanPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.transparent,
              AppTheme.homeSky.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.9),
              AppTheme.homeSky.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTRB(center.dx - 95, center.dy, center.dx + 95, center.dy),
          )
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final scanWidth = 190 * Curves.easeInOut.transform(scanReveal.clamp(0, 1));
    canvas.drawLine(
      Offset(center.dx - scanWidth / 2, center.dy),
      Offset(center.dx + scanWidth / 2, center.dy),
      scanPaint,
    );

    final pointPaint = Paint()
      ..color = baseColor.withValues(alpha: (isDark ? 0.75 : 0.85) * ringAmount);
    canvas.drawCircle(Offset(center.dx - 72, center.dy), 2.5, pointPaint);
    canvas.drawCircle(Offset(center.dx + 72, center.dy), 2.5, pointPaint);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashCount = 26;
    const dashSweep = math.pi / 32;
    const gapSweep = math.pi / 26;
    for (var index = 0; index < dashCount; index++) {
      final start = index * (dashSweep + gapSweep);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dashSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProcessingPainter oldDelegate) {
    return oldDelegate.orbReveal != orbReveal ||
        oldDelegate.ringReveal != ringReveal ||
        oldDelegate.scanReveal != scanReveal ||
        oldDelegate.pulse != pulse ||
        oldDelegate.isDark != isDark;
  }
}

TextStyle _monoStyle({
  required Color color,
  required double fontSize,
  required double letterSpacing,
  FontWeight fontWeight = FontWeight.w400,
}) {
  return GoogleFonts.jetBrainsMono(
    color: color,
    fontSize: fontSize,
    letterSpacing: letterSpacing,
    fontWeight: fontWeight,
  );
}

double _intervalValue(double value, double begin, double end) {
  if (value <= begin) return 0;
  if (value >= end) return 1;
  return Curves.easeOutCubic.transform((value - begin) / (end - begin));
}
