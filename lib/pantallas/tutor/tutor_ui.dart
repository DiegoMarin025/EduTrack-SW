import 'package:flutter/material.dart';

class TutorPalette {
  static const Color primaryBlue = Color(0xFF2D63ED);
  static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textSoft = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);
}

List<BoxShadow> tutorSoftShadow() {
  return const [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.05),
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];
}

BoxDecoration tutorSurfaceDecoration({
  Color color = Colors.white,
  double radius = 20,
  Color borderColor = TutorPalette.border,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: tutorSoftShadow(),
  );
}

Widget tutorSectionTitle(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 16.5,
      fontWeight: FontWeight.w900,
      color: Color(0xFF334155),
    ),
  );
}

class TutorPageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const TutorPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 640;

    final leadingBlock = Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: TutorPalette.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: TutorPalette.primaryBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: TutorPalette.darkBlue,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: TutorPalette.textSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leadingBlock,
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [leadingBlock]),
        if (trailing != null) ...[
          const SizedBox(height: 14),
          trailing!,
        ],
      ],
    );
  }
}

class TutorMetricCard extends StatelessWidget {
  final String value;
  final String label;
  final String detail;
  final IconData icon;
  final Color tint;

  const TutorMetricCard({
    super.key,
    required this.value,
    required this.label,
    required this.detail,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: tutorSurfaceDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tint, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: TutorPalette.textDark,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: TutorPalette.textSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: TutorPalette.textSoft.withValues(alpha: 0.90),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
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

class TutorActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  const TutorActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: tutorSurfaceDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: tint, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: TutorPalette.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: TutorPalette.textSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorStatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const TutorStatusBadge({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

Color tutorStatusColor(String status) {
  switch (status.toLowerCase()) {
    case "asistencia":
    case "registrado":
    case "entregada":
    case "aprobada":
      return TutorPalette.success;
    case "retardo":
    case "en revision":
      return TutorPalette.warning;
    case "falta":
    case "pendiente":
      return TutorPalette.danger;
    default:
      return TutorPalette.primaryBlue;
  }
}

String tutorWeekdayEs(int weekday) {
  const days = ["Lun", "Mar", "Mie", "Jue", "Vie", "Sab", "Dom"];
  return days[(weekday - 1).clamp(0, 6)];
}

String tutorMonthEs(int month) {
  const months = [
    "Ene",
    "Feb",
    "Mar",
    "Abr",
    "May",
    "Jun",
    "Jul",
    "Ago",
    "Sep",
    "Oct",
    "Nov",
    "Dic",
  ];
  return months[(month - 1).clamp(0, 11)];
}
