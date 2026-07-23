import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/person.dart';
import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';
import 'user_detail_page.dart';

String? _frontImagePath(Person p) {
  final front = p.faceImagePaths['front'];
  if (front != null && front.isNotEmpty) {
    final file = File(front.first);
    if (file.existsSync()) return front.first;
  }
  return null;
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  @override
  void initState() {
    super.initState();
    context.read<UsersCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Registered Users')),
      body: BlocBuilder<UsersCubit, UsersState>(
        builder: (context, state) {
          if (state is UsersLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFCA8A04)),
            );
          }

          if (state is UsersError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : const Color(0xFF1F1A14).withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load users',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F1A14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.45)
                            : const Color(0xFF1F1A14).withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.read<UsersCubit>().load(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFCA8A04),
                        foregroundColor: const Color(0xFF1C1917),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is UsersLoaded) {
            final persons = state.persons;

            if (persons.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 64,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : const Color(0xFF1F1A14).withValues(alpha: 0.15)),
                      const SizedBox(height: 20),
                      Text(
                        'No users registered yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F1A14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Register a person from the Settings page\nto see them here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : const Color(0xFF1F1A14).withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: persons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _UserCard(
                person: persons[index],
                isDark: isDark,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserDetailPage(person: persons[index]),
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Person person;
  final bool isDark;
  final VoidCallback onTap;

  const _UserCard({
    required this.person,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalAngles = person.faceImagePaths.length;
    final totalShots = person.faceImagePaths.values.fold(
      0,
      (sum, list) => sum + list.length,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFFE5D8C5),
          ),
        ),
        child: Row(
          children: [
            _ProfileAvatar(person: person, size: 50),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F1A14),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${person.employeeId}  ·  ${person.department}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : const Color(0xFF1F1A14).withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MetaChip(
                        label: '$totalAngles angles',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _MetaChip(
                        label: '$totalShots shots',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFF1F1A14).withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final Person person;
  final double size;

  const _ProfileAvatar({required this.person, required this.size});

  @override
  Widget build(BuildContext context) {
    final frontPath = _frontImagePath(person);
    if (frontPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(frontPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialAvatar(context),
        ),
      );
    }
    return _initialAvatar(context);
  }

  Widget _initialAvatar(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFCA8A04).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFFCA8A04),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _MetaChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : const Color(0xFF1F1A14).withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
