import 'package:flutter/material.dart';

class RegisterDoneStep extends StatelessWidget {
  final String name;
  final VoidCallback onRegisterAnother;

  const RegisterDoneStep({
    super.key,
    required this.name,
    required this.onRegisterAnother,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E676).withValues(alpha: 0.2),
                    const Color(0xFF00E676).withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF00E676),
                size: 54,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE6DAC7),
                ),
              ),
              child: Text(
                'Verification complete',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1F1A14),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$name is ready for attendance scanning.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F1A14),
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'All face angles were captured locally and are ready for recognition.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.52)
                    : const Color(0xFF1F1A14).withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCA8A04), Color(0xFFE48B12)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCA8A04).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: Color(0xFF1C1917),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRegisterAnother,
              child: const Text(
                'Register another person',
                style: TextStyle(color: Color(0xFFCA8A04)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
