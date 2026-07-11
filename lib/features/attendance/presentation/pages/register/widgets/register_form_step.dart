import 'package:flutter/material.dart';

class RegisterFormStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController idController;
  final TextEditingController departmentController;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final VoidCallback onNext;

  const RegisterFormStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.idController,
    required this.departmentController,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.88);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE6DAC7);

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KycHeroCard(isDark: isDark),
              const SizedBox(height: 18),
              _FlowPills(isDark: isDark, activeIndex: 0),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.18 : 0.05,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(text: 'Full Name', isDark: isDark),
                      const SizedBox(height: 8),
                      _FormField(
                        controller: nameController,
                        hint: 'e.g. Abebe Girma',
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter the full name'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(
                        text: 'Employee / Student ID',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _FormField(
                        controller: idController,
                        hint: 'e.g. EMP-00142',
                        icon: Icons.badge_outlined,
                        isDark: isDark,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter an ID'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(text: 'Department', isDark: isDark),
                      const SizedBox(height: 8),
                      _FormField(
                        controller: departmentController,
                        hint: 'e.g. Engineering',
                        icon: Icons.business_outlined,
                        isDark: isDark,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a department'
                            : null,
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: onNext,
                        child: Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFCA8A04), Color(0xFFE48B12)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFCA8A04,
                                ).withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to Photo Capture',
                                style: TextStyle(
                                  color: Color(0xFF1C1917),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF1C1917),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'We keep the data local for now, so registration stays fast and private.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.28)
                        : const Color(0xFF1F1A14).withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const _SectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.6)
            : const Color(0xFF1F1A14).withValues(alpha: 0.65),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1F1A14),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.25)
              : const Color(0xFF1F1A14).withValues(alpha: 0.35),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFCA8A04), size: 20),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5D8C5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5D8C5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCA8A04), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _KycHeroCard extends StatelessWidget {
  final bool isDark;

  const _KycHeroCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF111827).withValues(alpha: isDark ? 0.92 : 0.04),
            const Color(0xFFCA8A04).withValues(alpha: isDark ? 0.18 : 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE6DAC7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFCA8A04).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFFE8B04A),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identity verification',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1F1A14),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capture a clean set of facial angles. We guide the flow automatically.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : const Color(0xFF1F1A14).withValues(alpha: 0.56),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _MetaChip(label: 'Local save', icon: Icons.lock_rounded),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetaChip(
                  label: 'Auto capture',
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowPills extends StatelessWidget {
  final bool isDark;
  final int activeIndex;

  const _FlowPills({required this.isDark, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    const steps = ['Details', 'Capture', 'Review'];

    return Row(
      children: List.generate(steps.length, (index) {
        final active = index == activeIndex;
        final completed = index < activeIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == steps.length - 1 ? 0 : 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFCA8A04).withValues(alpha: 0.14)
                    : completed
                    ? const Color(0xFF00E676).withValues(alpha: 0.12)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? const Color(0xFFCA8A04).withValues(alpha: 0.35)
                      : completed
                      ? const Color(0xFF00E676).withValues(alpha: 0.25)
                      : isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE6DAC7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    completed
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 14,
                    color: completed
                        ? const Color(0xFF00E676)
                        : active
                        ? const Color(0xFFE8B04A)
                        : isDark
                        ? Colors.white.withValues(alpha: 0.45)
                        : const Color(0xFF1F1A14).withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    steps[index],
                    style: TextStyle(
                      color: active || completed
                          ? (isDark ? Colors.white : const Color(0xFF1F1A14))
                          : isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : const Color(0xFF1F1A14).withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFE8B04A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F1A14),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
