import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/theme_cubit.dart';

class HomeTopBar extends StatelessWidget {
  final VoidCallback onSettings;

  const HomeTopBar({super.key, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.62);
    final showDate = MediaQuery.sizeOf(context).width >= 380;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.homeDarkSurface : const Color(0xFFFBFAFA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.16)
                : AppTheme.homeLightText.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BAYN',
                  style: GoogleFonts.atkinsonHyperlegible(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.35,
                  ),
                ),
                Text(
                  'ATTENDANCE',
                  style: GoogleFonts.readexPro(
                    color: mutedColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (showDate) ...[
            _DateBadge(mutedColor: mutedColor),
            const SizedBox(width: 4),
          ],
          _HeaderActionButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            onPressed: context.read<ThemeCubit>().toggleTheme,
          ),
          _HeaderActionButton(
            tooltip: 'Open settings',
            icon: Icons.settings_outlined,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final Color mutedColor;

  const _DateBadge({required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: AppTheme.homeGold,
          ),
          const SizedBox(width: 6),
          Text(
            _formattedDate(DateTime.now()),
            style: GoogleFonts.readexPro(
              color: mutedColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class HomeHeroSection extends StatelessWidget {
  final VoidCallback onTap;

  const HomeHeroSection({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.62);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'GOOD MORNING',
          style: GoogleFonts.readexPro(
            color: mutedColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 10),
        const _LiveClock(),
        const SizedBox(height: 18),
        const _StatusPill(),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            'When you’re ready, look at the camera to record today’s attendance.',
            textAlign: TextAlign.center,
            style: GoogleFonts.readexPro(
              color: mutedColor,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const HomeProgressCard(),
        const SizedBox(height: 32),
        HomeScanAction(onTap: onTap),
      ],
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Text(
        _formattedTime(_now),
        key: ValueKey('${_now.hour}:${_now.minute}'),
        style: GoogleFonts.atkinsonHyperlegible(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 76,
          fontWeight: FontWeight.w700,
          height: 0.86,
          letterSpacing: -5.4,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB6DAD5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.homeStatusGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'On time for check-in',
            style: GoogleFonts.readexPro(
              color: const Color(0xFF276C5B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeProgressCard extends StatelessWidget {
  const HomeProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.62);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
                      'Today’s progress',
                      style: GoogleFonts.atkinsonHyperlegible(
                        color: theme.colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your attendance timeline',
                      style: GoogleFonts.readexPro(
                        color: mutedColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.schedule_outlined,
                size: 18,
                color: AppTheme.homeGold,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _ProgressTimeline(),
        ],
      ),
    );
  }
}

class _ProgressTimeline extends StatefulWidget {
  const _ProgressTimeline();

  @override
  State<_ProgressTimeline> createState() => _ProgressTimelineState();
}

class _ProgressTimelineState extends State<_ProgressTimeline> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.onSurface.withValues(alpha: 0.18);

    // Logic based on provided shift hours:
    // Check-in: 8:00 AM - 8:30 AM (assuming 3:30 AM was a typo for 8:30 AM)
    // Lunch: 1:30 PM - 2:15 PM
    // Check-out: 5:00 PM - 6:00 PM

    final int currentMinutes = _now.hour * 60 + _now.minute;

    const int checkInStart = 8 * 60; // 8:00 AM
    const int checkInEnd = 8 * 60 + 30; // 8:30 AM

    const int lunchStart = 13 * 60 + 30; // 1:30 PM
    const int lunchEnd = 14 * 60 + 15; // 2:15 PM

    const int checkOutStart = 17 * 60; // 5:00 PM
    const int checkOutEnd = 18 * 60; // 6:00 PM

    bool checkInActive = false;
    bool checkInCompleted = false;
    bool lunchActive = false;
    bool lunchCompleted = false;
    bool checkOutActive = false;
    bool checkOutCompleted = false;

    // Check-in logic
    if (currentMinutes >= checkInStart && currentMinutes <= checkInEnd) {
      checkInActive = true;
    } else if (currentMinutes > checkInEnd) {
      checkInCompleted = true;
    }

    // Lunch logic
    if (currentMinutes >= lunchStart && currentMinutes <= lunchEnd) {
      lunchActive = true;
    } else if (currentMinutes > lunchEnd) {
      lunchCompleted = true;
    }

    // Check-out logic
    if (currentMinutes >= checkOutStart && currentMinutes <= checkOutEnd) {
      checkOutActive = true;
    } else if (currentMinutes > checkOutEnd) {
      checkOutCompleted = true;
    }

    String getStatus(bool active, bool completed) {
      if (active) return 'Pending';
      if (completed) return 'Completed';
      return 'Upcoming';
    }

    Color getAccent(bool active, bool completed) {
      if (completed) return AppTheme.homeStatusGreen;
      if (active) return AppTheme.homeGold;
      return const Color(0xFF9C9992);
    }

    return SizedBox(
      height: 76,
      child: Stack(
        children: [
          Positioned(
            top: 11,
            left: 12,
            right: 12,
            child: Container(height: 1, color: lineColor),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProgressStep(
                  label: 'Check-in',
                  status: getStatus(checkInActive, checkInCompleted),
                  alignment: CrossAxisAlignment.start,
                  accent: getAccent(checkInActive, checkInCompleted),
                  active: checkInActive,
                  completed: checkInCompleted,
                ),
              ),
              Expanded(
                child: _ProgressStep(
                  label: 'Lunch',
                  status: getStatus(lunchActive, lunchCompleted),
                  alignment: CrossAxisAlignment.center,
                  accent: getAccent(lunchActive, lunchCompleted),
                  active: lunchActive,
                  completed: lunchCompleted,
                ),
              ),
              Expanded(
                child: _ProgressStep(
                  label: 'Check-out',
                  status: getStatus(checkOutActive, checkOutCompleted),
                  alignment: CrossAxisAlignment.end,
                  accent: getAccent(checkOutActive, checkOutCompleted),
                  active: checkOutActive,
                  completed: checkOutCompleted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String label;
  final String status;
  final CrossAxisAlignment alignment;
  final Color accent;
  final bool active;
  final bool completed;

  const _ProgressStep({
    required this.label,
    required this.status,
    required this.alignment,
    required this.accent,
    this.active = false,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighlighted = active || completed;
    final textColor = theme.colorScheme.onSurface.withValues(
      alpha: isHighlighted ? 0.9 : 0.68,
    );
    final statusColor = theme.colorScheme.onSurface.withValues(
      alpha: isHighlighted ? 0.62 : 0.4,
    );

    IconData getIcon() {
      if (completed) return Icons.check;
      if (active) return Icons.radio_button_unchecked;
      return Icons.more_horiz;
    }

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: completed
                ? accent.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: isHighlighted ? 2 : 1),
          ),
          child: Icon(getIcon(), size: active ? 13 : 14, color: accent),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: GoogleFonts.atkinsonHyperlegible(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          status,
          style: GoogleFonts.readexPro(color: statusColor, fontSize: 10),
        ),
      ],
    );
  }
}

class HomeScanAction extends StatefulWidget {
  final VoidCallback onTap;

  const HomeScanAction({super.key, required this.onTap});

  @override
  State<HomeScanAction> createState() => _HomeScanActionState();
}

class _HomeScanActionState extends State<HomeScanAction> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.62);

    return Semantics(
      button: true,
      label: 'Begin face scan',
      hint: 'Opens the attendance camera',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (isHighlighted) {
                if (mounted) setState(() => _isPressed = isHighlighted);
              },
              borderRadius: BorderRadius.circular(72),
              child: AnimatedScale(
                scale: _isPressed ? 0.96 : 1,
                duration: const Duration(milliseconds: 130),
                curve: Curves.easeOut,
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: AppTheme.homeGold,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF6B531D)
                          : const Color(0xFFF3E5C4),
                      width: 8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.homeGold.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.face_retouching_natural_outlined,
                    size: 46,
                    color: theme.brightness == Brightness.dark
                        ? AppTheme.homeDarkText
                        : AppTheme.homeLightText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Begin face scan',
            style: GoogleFonts.atkinsonHyperlegible(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Takes only a few seconds',
            style: GoogleFonts.readexPro(color: mutedColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class HomeBottomNote extends StatelessWidget {
  const HomeBottomNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 17,
            color: AppTheme.homeStatusGreen,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Processed on-device. Never stored.',
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formattedDate(DateTime date) {
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
  return 'Today · ${date.day} ${months[date.month - 1]}';
}

String _formattedTime(DateTime time) {
  final hour = time.hour == 0
      ? 12
      : time.hour > 12
      ? time.hour - 12
      : time.hour;
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
}
