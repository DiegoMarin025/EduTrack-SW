import 'package:flutter/material.dart';

import 'tutor_demo_data.dart';
import 'tutor_ui.dart';

class TutorGradesScreen extends StatelessWidget {
  final TutorStudentSnapshot snapshot;

  const TutorGradesScreen({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWebWide = width >= 960;
    final isTablet = width >= 640;

    return Scaffold(
      backgroundColor: TutorPalette.bgLight,
      appBar: AppBar(
        title: const Text("Calificaciones"),
        backgroundColor: TutorPalette.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWebWide ? 1120 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWebWide ? 28 : 20,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TutorPageHeader(
                    icon: Icons.grade_rounded,
                    title: "Calificaciones de ${snapshot.studentName}",
                    subtitle:
                        "Consulta promedio general, promedio por materia y desglose por parcial.",
                    trailing: _dateChip(),
                  ),
                  const SizedBox(height: 16),
                  _buildHeroCard(isTablet),
                  const SizedBox(height: 16),
                  _buildMetricsGrid(isWebWide, isTablet),
                  const SizedBox(height: 18),
                  tutorSectionTitle("Promedio por materia"),
                  const SizedBox(height: 12),
                  _buildSubjectCards(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateChip() {
    final now = DateTime.now();
    final text =
        "${tutorWeekdayEs(now.weekday)} ${now.day} ${tutorMonthEs(now.month)}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TutorPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 18,
            color: TutorPalette.primaryBlue,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isTablet) {
    final best = snapshot.strongestSubject;
    final hasGrades = snapshot.grades.isNotEmpty;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            "RESUMEN ACADEMICO",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "Promedio general",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          snapshot.generalAverage.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          hasGrades
              ? "La materia mas fuerte actualmente es ${best.subjectName.toLowerCase()} con ${best.average.toStringAsFixed(1)}."
              : "Aqui se mostrara el resumen academico cuando existan materias y calificaciones vinculadas.",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ],
    );

    final pills = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        _heroPill(
          icon: Icons.menu_book_rounded,
          title: "${snapshot.grades.length}",
          subtitle: "Materias",
        ),
        _heroPill(
          icon: Icons.check_circle_rounded,
          title: _approvedCount().toString(),
          subtitle: "Aprobadas",
        ),
        _heroPill(
          icon: Icons.trending_up_rounded,
          title: hasGrades ? best.average.toStringAsFixed(1) : "--",
          subtitle: "Mejor promedio",
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TutorPalette.primaryBlue, TutorPalette.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TutorPalette.primaryBlue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: isTablet
            ? Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 14),
                  pills,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  details,
                  const SizedBox(height: 16),
                  pills,
                ],
              ),
      ),
    );
  }

  Widget _buildMetricsGrid(bool isWebWide, bool isTablet) {
    // "3 parciales" es el contrato visual actual.
    // Si el nuevo backend/Firebase trae 2, 4 o N parciales, ajustar aqui el resumen
    // y tambien la forma en que se arma snapshot.grades.
    final metrics = [
      TutorMetricCard(
        value: snapshot.generalAverage.toStringAsFixed(1),
        label: "Promedio general",
        detail: "Acumulado del periodo",
        icon: Icons.auto_graph_rounded,
        tint: TutorPalette.primaryBlue,
      ),
      TutorMetricCard(
        value: "${snapshot.grades.length}",
        label: "Promedio por materia",
        detail: "Materias visibles en el corte",
        icon: Icons.menu_book_rounded,
        tint: TutorPalette.success,
      ),
      TutorMetricCard(
        value: "3",
        label: "Desglose por parcial",
        detail: "Tres cortes por materia",
        icon: Icons.filter_3_rounded,
        tint: TutorPalette.warning,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWebWide ? 3 : (isTablet ? 2 : 1),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWebWide ? 2.2 : (isTablet ? 2.2 : 2.8),
      ),
      itemBuilder: (context, index) => metrics[index],
    );
  }

  Widget _buildSubjectCards() {
    // Esta vista ya consume datos normalizados del snapshot.
    // La siguiente persona solo necesita cambiar la construccion del snapshot
    // si quiere parciales/comentarios reales; no hace falta redisenar esta UI.
    if (snapshot.grades.isEmpty) {
      return tutorEmptyStateCard(
        icon: Icons.grade_rounded,
        title: "Aqui apareceran las calificaciones",
        message:
            "Cuando el alumno tenga materias y evaluaciones vinculadas, se mostraran el promedio, parciales y comentarios del maestro.",
      );
    }

    return Column(
      children: snapshot.grades.map((subject) {
        final statusColor = subject.average >= 9
            ? TutorPalette.success
            : (subject.average >= 8
                  ? TutorPalette.primaryBlue
                  : TutorPalette.warning);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: tutorSurfaceDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.book_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.subjectName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: TutorPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subject.teacherName,
                            style: const TextStyle(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w600,
                              color: TutorPalette.textSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TutorStatusBadge(
                          text: "Promedio ${subject.average.toStringAsFixed(1)}",
                          color: statusColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subject.average >= 7 ? "Buen avance" : "Requiere apoyo",
                          style: const TextStyle(
                            color: TutorPalette.textSoft,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(subject.partials.length, (index) {
                    final partial = subject.partials[index];
                    final partialColor = partial >= 9
                        ? TutorPalette.success
                        : (partial >= 8
                              ? TutorPalette.primaryBlue
                              : TutorPalette.warning);

                    return Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: partialColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: partialColor.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Parcial ${index + 1}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: TutorPalette.textSoft,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            partial.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: partialColor,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TutorPalette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Comentario del maestro",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: TutorPalette.textSoft,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subject.teacherNote,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TutorPalette.textDark,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  int _approvedCount() {
    return snapshot.grades.where((subject) => subject.average >= 7).length;
  }

  Widget _heroPill({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
