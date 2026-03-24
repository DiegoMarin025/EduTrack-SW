import 'package:flutter/material.dart';

import 'tutor_demo_data.dart';
import 'tutor_live_data_service.dart';
import 'tutor_ui.dart';

class TutorGradesScreen extends StatefulWidget {
  final TutorStudentSnapshot snapshot;
  final int userId;
  final String tutorName;

  const TutorGradesScreen({
    super.key,
    required this.snapshot,
    required this.userId,
    required this.tutorName,
  });

  @override
  State<TutorGradesScreen> createState() => _TutorGradesScreenState();
}

class _TutorGradesScreenState extends State<TutorGradesScreen> {
  late TutorStudentSnapshot _snapshot;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.snapshot;
    _refreshSnapshot();
  }

  Future<void> _refreshSnapshot() async {
    setState(() => _syncing = true);

    try {
      final latest = await TutorLiveDataService.loadSnapshot(
        sessionUserId: widget.userId,
        tutorName: widget.tutorName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = latest;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron actualizar las calificaciones: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

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
        actions: [
          IconButton(
            tooltip: "Actualizar",
            onPressed: _syncing ? null : _refreshSnapshot,
            icon: _syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWebWide ? 1120 : double.infinity,
            ),
            child: RefreshIndicator(
              onRefresh: _refreshSnapshot,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWebWide ? 28 : 20,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TutorPageHeader(
                      icon: Icons.grade_rounded,
                      title: "Calificaciones de ${_snapshot.studentName}",
                      subtitle:
                          "Consulta promedio general, materias y evaluaciones registradas por el maestro.",
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
    final gradedSubjects = _snapshot.grades
        .where((subject) => subject.hasRecordedAverage)
        .toList();
    final best = _snapshot.strongestSubject;
    final hasGrades = gradedSubjects.isNotEmpty;
    final averageLabel = hasGrades
        ? _snapshot.generalAverage.toStringAsFixed(1)
        : "--";

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
          averageLabel,
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
              ? "La materia con mejor registro es ${best.subjectName.toLowerCase()} con ${best.average.toStringAsFixed(1)}."
              : "Aqui se mostrara el resumen academico cuando el maestro registre evaluaciones reales para el alumno.",
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
          title: "${_snapshot.grades.length}",
          subtitle: "Materias",
        ),
        _heroPill(
          icon: Icons.check_circle_rounded,
          title: _gradedSubjectsCount().toString(),
          subtitle: "Calificadas",
        ),
        _heroPill(
          icon: Icons.pending_actions_rounded,
          title: _subjectsInProgressCount().toString(),
          subtitle: "En seguimiento",
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
    final metrics = [
      TutorMetricCard(
        value: _gradedSubjectsCount() > 0
            ? _snapshot.generalAverage.toStringAsFixed(1)
            : "--",
        label: "Promedio general",
        detail: "Solo materias con nota real",
        icon: Icons.auto_graph_rounded,
        tint: TutorPalette.primaryBlue,
      ),
      TutorMetricCard(
        value: "${_gradedSubjectsCount()}",
        label: "Materias calificadas",
        detail: "${_snapshot.grades.length} visibles en total",
        icon: Icons.menu_book_rounded,
        tint: TutorPalette.success,
      ),
      TutorMetricCard(
        value: "${_subjectsInProgressCount()}",
        label: "Materias en seguimiento",
        detail: "Con actividades pendientes de calificar",
        icon: Icons.pending_actions_rounded,
        tint: TutorPalette.info,
      ),
      TutorMetricCard(
        value: "${_evaluationCount()}",
        label: "Evaluaciones",
        detail: "Registros capturados por materia",
        icon: Icons.fact_check_rounded,
        tint: TutorPalette.warning,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWebWide ? 4 : (isTablet ? 2 : 1),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWebWide ? 2.15 : (isTablet ? 2.2 : 2.8),
      ),
      itemBuilder: (context, index) => metrics[index],
    );
  }

  Widget _buildSubjectCards() {
    if (_snapshot.grades.isEmpty) {
      return tutorEmptyStateCard(
        icon: Icons.grade_rounded,
        title: "Aqui apareceran las calificaciones",
        message:
            "Cuando el maestro registre evaluaciones o cierre la materia, veras el promedio y los comentarios en esta seccion.",
      );
    }

    return Column(
      children: _snapshot.grades.map((subject) {
        final statusColor = !subject.hasRecordedAverage
            ? TutorPalette.info
            : subject.average >= 9
            ? TutorPalette.success
            : (subject.average >= 8
                  ? TutorPalette.primaryBlue
                  : (subject.average >= 7
                        ? TutorPalette.warning
                        : TutorPalette.danger));

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
                          text: subject.hasRecordedAverage
                              ? "Promedio ${subject.average.toStringAsFixed(1)}"
                              : "Sin calificacion",
                          color: statusColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subject.progressLabel,
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
                subject.partials.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TutorPalette.border),
                        ),
                        child: Text(
                          _emptyEvaluationMessage(subject),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TutorPalette.textSoft,
                            height: 1.45,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(subject.partials.length, (index) {
                          final evaluation = subject.partials[index];
                          final label = index < subject.evaluationLabels.length
                              ? subject.evaluationLabels[index]
                              : "Evaluacion ${index + 1}";
                          final partialColor = evaluation >= 9
                              ? TutorPalette.success
                              : (evaluation >= 8
                                    ? TutorPalette.primaryBlue
                                    : (evaluation >= 7
                                          ? TutorPalette.warning
                                          : TutorPalette.danger));

                          return Container(
                            width: 170,
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
                                  label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: TutorPalette.textSoft,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  evaluation.toStringAsFixed(1),
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
                if (subject.trackedItemsCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: TutorPalette.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          size: 18,
                          color: TutorPalette.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _trackedItemsMessage(subject),
                            style: const TextStyle(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w700,
                              color: TutorPalette.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  int _gradedSubjectsCount() {
    return _snapshot.grades.where((subject) => subject.hasRecordedAverage).length;
  }

  int _evaluationCount() {
    return _snapshot.grades.fold<int>(
      0,
      (sum, subject) => sum + subject.partials.length,
    );
  }

  int _subjectsInProgressCount() {
    return _snapshot.grades.where((subject) {
      return !subject.hasRecordedAverage && subject.trackedItemsCount > 0;
    }).length;
  }

  String _emptyEvaluationMessage(TutorSubjectGrade subject) {
    if (subject.trackedItemsCount > 0) {
      return "El maestro ya registro actividades en esta materia, pero aun no les asigna calificacion al alumno.";
    }

    return "Aun no hay evaluaciones con calificacion registradas para esta materia.";
  }

  String _trackedItemsMessage(TutorSubjectGrade subject) {
    final scoredCount = subject.partials.length;
    final trackedCount = subject.trackedItemsCount;

    if (trackedCount <= 0) {
      return "Sin actividades registradas todavia.";
    }

    if (scoredCount <= 0) {
      return "$trackedCount actividades registradas, pendientes de calificar.";
    }

    if (trackedCount > scoredCount) {
      return "$scoredCount de $trackedCount actividades ya tienen calificacion.";
    }

    return "$scoredCount actividades calificadas en esta materia.";
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
