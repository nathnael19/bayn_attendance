import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
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

  Future<void> _syncFromServer() async {
    setState(() => _isSyncing = true);
    try {
      final repo = di.sl<PersonRepository>();
      final result = await repo.pullFromServer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synced ${result.employeesSynced} employees with '
            '${result.embeddingsSynced} embeddings',
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } on BackendNotConfiguredException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Backend not configured. Set BAYN_API_BASE_URL.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'People',
            description: 'Add new employees or students so they can be recognized during attendance scans.',
            children: [
              _ActionButton(
                icon: Icons.person_add_rounded,
                label: 'Register a Person',
                gradient: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => di.sl<RegisterCubit>(),
                      child: const RegisterPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.people_rounded,
                label: 'View Users',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => di.sl<UsersCubit>(),
                      child: const UsersPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Sync',
            description: 'Download all employees and face embeddings from the server. Existing local data will be replaced.',
            children: [
              _ActionButton(
                icon: Icons.cloud_download_rounded,
                label: _isSyncing ? 'Syncing…' : 'Sync from Server',
                loading: _isSyncing,
                enabled: !_isSyncing,
                onTap: _syncFromServer,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'The attendance scanner keeps its camera-focused treatment, while the rest of the app follows the selected theme.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool gradient;
  final bool loading;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.gradient = false,
    this.loading = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: gradient ? const Color(0xFF1C1917) : (isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1F1A14).withValues(alpha: 0.7)),
            ),
          )
        else
          Icon(icon, size: 18,
            color: gradient ? const Color(0xFF1C1917) : (isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1F1A14).withValues(alpha: 0.7)),
          ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: gradient ? const Color(0xFF1C1917) : (isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF1F1A14).withValues(alpha: 0.85)),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.6,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient
                ? const LinearGradient(
                    colors: [Color(0xFFCA8A04), Color(0xFFD97706)],
                  )
                : null,
            color: gradient
                ? null
                : isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            boxShadow: gradient
                ? [
                    BoxShadow(
                      color: const Color(0xFFCA8A04).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            border: gradient
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
          ),
          child: content,
        ),
      ),
    );
  }
}
