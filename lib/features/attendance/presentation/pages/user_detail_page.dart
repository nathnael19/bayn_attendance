import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/person.dart';

String? _frontImagePath(Person p) {
  final front = p.faceImagePaths['front'];
  if (front != null && front.isNotEmpty) {
    final file = File(front.first);
    if (file.existsSync()) return front.first;
  }
  return null;
}

class UserDetailPage extends StatelessWidget {
  final Person person;

  const UserDetailPage({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(person.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeaderCard(person: person, isDark: isDark),
          const SizedBox(height: 20),
          _InfoCard(person: person, isDark: isDark),
          const SizedBox(height: 20),
          _FaceImagesCard(person: person, isDark: isDark),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Person person;
  final bool isDark;

  const _HeaderCard({required this.person, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE5D8C5),
        ),
      ),
      child: Column(
        children: [
          _DetailAvatar(person: person),
          const SizedBox(height: 16),
          Text(
            person.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1F1A14),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            person.employeeId,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : const Color(0xFF1F1A14).withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          _SyncBadge(isSynced: person.isSynced, isDark: isDark),
        ],
      ),
    );
  }
}

class _DetailAvatar extends StatelessWidget {
  final Person person;

  const _DetailAvatar({required this.person});

  @override
  Widget build(BuildContext context) {
    final frontPath = _frontImagePath(person);
    if (frontPath != null) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCA8A04).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(
            File(frontPath),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _initialAvatar(),
          ),
        ),
      );
    }
    return _initialAvatar();
  }

  Widget _initialAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCA8A04), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCA8A04).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFF1C1917),
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final bool isSynced;
  final bool isDark;

  const _SyncBadge({required this.isSynced, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isSynced ? const Color(0xFF00E676) : const Color(0xFFCA8A04);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            isSynced ? 'Synced' : 'Local only',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Person person;
  final bool isDark;

  const _InfoCard({required this.person, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE5D8C5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F1A14),
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Name', value: person.name, isDark: isDark),
          _InfoRow(
            label: 'Employee ID',
            value: person.employeeId,
            isDark: isDark,
          ),
          _InfoRow(
            label: 'Department',
            value: person.department,
            isDark: isDark,
          ),
          _InfoRow(
            label: 'Role',
            value: person.role[0].toUpperCase() + person.role.substring(1),
            isDark: isDark,
          ),
          if (person.phone != null)
            _InfoRow(label: 'Phone', value: person.phone!, isDark: isDark),
          if (person.email != null)
            _InfoRow(label: 'Email', value: person.email!, isDark: isDark),
          _InfoRow(
            label: 'Status',
            value: person.isActive ? 'Active' : 'Inactive',
            isDark: isDark,
          ),
          if (person.shiftId != null)
            _InfoRow(
              label: 'Shift',
              value: 'Shift #${person.shiftId}',
              isDark: isDark,
            ),
          _InfoRow(
            label: 'Registered',
            value: _formatDate(person.registeredAt),
            isDark: isDark,
          ),
          _InfoRow(
            label: 'Server ID',
            value: person.serverId ?? '—',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
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
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} $day, $hour:$minute';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : const Color(0xFF1F1A14).withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F1A14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceImagesCard extends StatelessWidget {
  final Person person;
  final bool isDark;

  const _FaceImagesCard({required this.person, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final angles = person.faceImagePaths.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE5D8C5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Face Images',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F1A14),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${angles.length} angles  ·  ${person.faceImagePaths.values.fold(0, (s, l) => s + l.length)} total shots',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : const Color(0xFF1F1A14).withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 16),
          ...angles.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCA8A04).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFCA8A04),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: entry.value.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final file = File(entry.value[i]);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: file.existsSync()
                              ? Image.file(
                                  file,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _imagePlaceholder(isDark),
                                )
                              : _imagePlaceholder(isDark),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        color: isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.12),
      ),
    );
  }
}
