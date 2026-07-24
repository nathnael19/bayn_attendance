import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/embedding_local_datasource.dart';
import '../../data/datasources/person_remote_datasource.dart';
import '../../domain/repositories/person_repository.dart';
import '../cubit/register_cubit.dart';
import '../cubit/users_cubit.dart';
import 'register_page.dart';
import 'users_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isSyncing = false;
  int _enrolledUsers = 0;
  int _faceEmbeddings = 0;
  String _lastSyncLabel = 'Last sync · Not yet synced';

  @override
  void initState() {
    super.initState();
    _loadLocalStats();
  }

  Future<void> _loadLocalStats() async {
    if (!di.sl.isRegistered<PersonRepository>() ||
        !di.sl.isRegistered<EmbeddingLocalDatasource>()) {
      return;
    }

    try {
      final persons = await di.sl<PersonRepository>().getAllPersons();
      final embeddings = await di
          .sl<EmbeddingLocalDatasource>()
          .getEmbeddingCount();
      if (!mounted) return;
      setState(() {
        _enrolledUsers = persons.length;
        _faceEmbeddings = embeddings;
      });
    } catch (_) {
      // Stats are supplemental; the settings actions remain usable if they fail.
    }
  }

  Future<void> _syncFromServer() async {
    setState(() => _isSyncing = true);
    try {
      final repo = di.sl<PersonRepository>();
      final result = await repo.pullFromServer();
      if (!mounted) return;

      setState(() {
        _enrolledUsers = result.employeesSynced;
        _faceEmbeddings = result.embeddingsSynced;
        _lastSyncLabel = _formatLastSync(DateTime.now());
      });

      _showSnackBar(
        'Synced ${result.employeesSynced} employees with '
        '${result.embeddingsSynced} embeddings',
        backgroundColor: Colors.green.shade700,
      );
    } on BackendNotConfiguredException {
      if (!mounted) return;
      _showSnackBar(
        'Backend not configured. Set BAYN_API_BASE_URL.',
        backgroundColor: Colors.orange.shade700,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Sync failed: $e', backgroundColor: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatLastSync(DateTime timestamp) {
    final hour = timestamp.hour == 0
        ? 12
        : timestamp.hour > 12
        ? timestamp.hour - 12
        : timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final meridiem = timestamp.hour >= 12 ? 'PM' : 'AM';
    return 'Last sync · Today, $hour:$minute $meridiem';
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<RegisterCubit>(),
          child: const RegisterPage(),
        ),
      ),
    );
  }

  void _openUsers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<UsersCubit>(),
          child: UsersPage(onEnroll: _openRegister),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _SettingsColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsHeader(colors: colors),
                    const SizedBox(height: 30),
                    _TitleBlock(colors: colors),
                    const SizedBox(height: 32),
                    _PeopleSection(
                      colors: colors,
                      enrolledUsers: _enrolledUsers,
                      onEnroll: _openRegister,
                      onViewUsers: _openUsers,
                    ),
                    const SizedBox(height: 32),
                    _SyncSection(
                      colors: colors,
                      lastSyncLabel: _lastSyncLabel,
                      enrolledUsers: _enrolledUsers,
                      faceEmbeddings: _faceEmbeddings,
                      isSyncing: _isSyncing,
                      onSync: _isSyncing ? null : _syncFromServer,
                    ),
                    const SizedBox(height: 72),
                    _PrivacyFooter(colors: colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final _SettingsColors colors;

  const _SettingsHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          button: true,
          label: 'Go back',
          child: Tooltip(
            message: 'Go back',
            child: Material(
              color: colors.surface,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: colors.text,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'BAYN',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              _MicroLabel('ATTENDANCE', color: colors.muted, fontSize: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final _SettingsColors colors;

  const _TitleBlock({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MicroLabel('CONTROL SURFACE / 01', color: colors.muted),
                  const SizedBox(height: 10),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 0.94,
                      letterSpacing: -2.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _StatusBadge(colors: colors),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            'Manage who can be recognized and keep the attendance engine in sync.',
            style: TextStyle(
              color: colors.mutedStrong,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _SettingsColors colors;

  const _StatusBadge({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.statusSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.statusBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.success.withValues(alpha: 0.18),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MicroLabel('SYSTEM READY', color: colors.successDark, fontSize: 9),
        ],
      ),
    );
  }
}

class _PeopleSection extends StatelessWidget {
  final _SettingsColors colors;
  final int enrolledUsers;
  final VoidCallback onEnroll;
  final VoidCallback onViewUsers;

  const _PeopleSection({
    required this.colors,
    required this.enrolledUsers,
    required this.onEnroll,
    required this.onViewUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsSectionHeader(
          colors: colors,
          index: '01 / IDENTITY',
          title: 'People',
          trailing: 'LOCAL INDEX',
          accent: colors.gold,
        ),
        const SizedBox(height: 12),
        _TactileSurface(
          colors: colors,
          borderRadius: 24,
          child: Column(
            children: [
              SizedBox(
                height: 164,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SettingsActionTile(
                        colors: colors,
                        icon: Icons.person_add_alt_1_rounded,
                        iconBackground: colors.goldSoft,
                        iconColor: colors.goldText,
                        title: 'Enroll new face',
                        description: 'Add a person to the recognition index.',
                        onTap: onEnroll,
                      ),
                    ),
                    Container(width: 1, color: colors.divider),
                    Expanded(
                      child: _SettingsActionTile(
                        colors: colors,
                        icon: Icons.groups_rounded,
                        iconBackground: colors.tealSoft,
                        iconColor: colors.success,
                        title: 'View users',
                        description: 'Review enrolled people.',
                        trailing: enrolledUsers.toString(),
                        onTap: onViewUsers,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: colors.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 16,
                      color: colors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Face data stays on this device until synced.',
                        style: TextStyle(
                          color: colors.mutedStrong,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncSection extends StatelessWidget {
  final _SettingsColors colors;
  final String lastSyncLabel;
  final int enrolledUsers;
  final int faceEmbeddings;
  final bool isSyncing;
  final VoidCallback? onSync;

  const _SyncSection({
    required this.colors,
    required this.lastSyncLabel,
    required this.enrolledUsers,
    required this.faceEmbeddings,
    required this.isSyncing,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsSectionHeader(
          colors: colors,
          index: '02 / CONNECTION',
          title: 'Server sync',
          trailing: 'PULL ONLY',
          accent: colors.sky,
          trailingBottomPadding: 2,
        ),
        const SizedBox(height: 12),
        _TactileSurface(
          colors: colors,
          borderRadius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MicroLabel(
                            'LAST SYNC',
                            color: colors.muted,
                            fontSize: 9,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            lastSyncLabel,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '$enrolledUsers employees · $faceEmbeddings face embeddings',
                            style: TextStyle(
                              color: colors.mutedStrong,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _SyncButton(
                    colors: colors,
                    isSyncing: isSyncing,
                    onTap: onSync,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: colors.divider),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: colors.warningDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Server payload replaces local people and face embeddings.',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncButton extends StatelessWidget {
  final _SettingsColors colors;
  final bool isSyncing;
  final VoidCallback? onTap;

  const _SyncButton({
    required this.colors,
    required this.isSyncing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Sync from server',
      child: Material(
        color: colors.gold,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 122,
            height: 112,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: onTap == null ? 0.65 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSyncing)
                    const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.homeLightText,
                      ),
                    )
                  else
                    Icon(
                      Icons.cloud_download_outlined,
                      color: colors.darkText,
                      size: 23,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    isSyncing ? 'Syncing…' : 'Sync from\nserver',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyFooter extends StatelessWidget {
  final _SettingsColors colors;

  const _PrivacyFooter({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.statusSurface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.statusBorder),
            ),
            child: Icon(Icons.shield_outlined, color: colors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MicroLabel(
                  'PRIVACY BY DEFAULT',
                  color: colors.success,
                  fontSize: 9,
                ),
                const SizedBox(height: 4),
                Text(
                  'On-device processing. Never stored.',
                  style: TextStyle(
                    color: colors.mutedStrong,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final _SettingsColors colors;
  final String index;
  final String title;
  final String trailing;
  final Color accent;
  final double trailingBottomPadding;

  const _SettingsSectionHeader({
    required this.colors,
    required this.index,
    required this.title,
    required this.trailing,
    required this.accent,
    this.trailingBottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 4,
          height: 30,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MicroLabel(index, color: colors.muted, fontSize: 10),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: trailingBottomPadding),
          child: _MicroLabel(trailing, color: colors.mutedLight, fontSize: 10),
        ),
      ],
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final _SettingsColors colors;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.colors,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    _MicroLabel(trailing!, color: colors.success, fontSize: 10),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TactileSurface extends StatelessWidget {
  final _SettingsColors colors;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const _TactileSurface({
    required this.colors,
    required this.child,
    this.borderRadius = 24,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _MicroLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const _MicroLabel(this.text, {required this.color, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: fontSize <= 9 ? 1.05 : 0.9,
        height: 1,
      ),
    );
  }
}

class _SettingsColors {
  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color mutedStrong;
  final Color mutedLight;
  final Color border;
  final Color divider;
  final Color gold;
  final Color goldSoft;
  final Color goldText;
  final Color sky;
  final Color tealSoft;
  final Color success;
  final Color successDark;
  final Color statusSurface;
  final Color statusBorder;
  final Color warningDark;
  final Color darkText;

  const _SettingsColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.mutedStrong,
    required this.mutedLight,
    required this.border,
    required this.divider,
    required this.gold,
    required this.goldSoft,
    required this.goldText,
    required this.sky,
    required this.tealSoft,
    required this.success,
    required this.successDark,
    required this.statusSurface,
    required this.statusBorder,
    required this.warningDark,
    required this.darkText,
  });

  factory _SettingsColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _SettingsColors(
        background: AppTheme.homeDarkBackground,
        surface: AppTheme.homeDarkSurface,
        text: AppTheme.homeDarkText,
        muted: Color(0xFFB5B3AA),
        mutedStrong: Color(0xFFD0CEC5),
        mutedLight: Color(0xFF8E8D86),
        border: Color(0xFF4A4943),
        divider: Color(0xFF57564E),
        gold: AppTheme.homeGold,
        goldSoft: Color(0xFF5F4E21),
        goldText: Color(0xFFF0D27D),
        sky: Color(0xFF38BDF8),
        tealSoft: Color(0xFF234A43),
        success: Color(0xFF61B59D),
        successDark: Color(0xFF9BDCC8),
        statusSurface: Color(0xFF203B36),
        statusBorder: Color(0xFF477C6F),
        warningDark: Color(0xFFE7B857),
        darkText: Color(0xFF272724),
      );
    }

    return const _SettingsColors(
      background: AppTheme.homeLightBackground,
      surface: AppTheme.homeWarmSurface,
      text: AppTheme.homeLightText,
      muted: Color(0xFF77756C),
      mutedStrong: Color(0xFF66655D),
      mutedLight: Color(0xFF9B978C),
      border: Color(0xFFE5E4E2),
      divider: Color(0xFFD9D4CC),
      gold: Color(0xFFD49A1C),
      goldSoft: Color(0xFFEAD49A),
      goldText: Color(0xFF665018),
      sky: AppTheme.homeSky,
      tealSoft: Color(0xFFE5E8E6),
      success: Color(0xFF2C8B74),
      successDark: Color(0xFF276C5B),
      statusSurface: Color(0xFFF1F8F5),
      statusBorder: Color(0xFFB6DAD5),
      warningDark: Color(0xFF9A6A13),
      darkText: Color(0xFF3B3C36),
    );
  }
}
