import 'package:flutter/material.dart';

import 'tutor_absence_justification_screen.dart';
import 'tutor_activities_screen.dart';
import 'tutor_attendance_screen.dart';
import 'tutor_demo_data.dart';
import 'tutor_grades_screen.dart';
import 'tutor_ui.dart';

class TutorDashboard extends StatefulWidget {
  final int userId;
  final String username;

  const TutorDashboard({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<TutorDashboard> createState() => _TutorDashboardState();
}

class _TutorDashboardState extends State<TutorDashboard> {
  late final TutorStudentSnapshot _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = buildTutorDemoData(tutorName: widget.username);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWebWide = width >= 960;
    final isTablet = width >= 640;

    return Container(
      color: TutorPalette.bgLight,
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
                _buildTopHeader(isTablet),
                const SizedBox(height: 16),
                _buildHeroCard(isTablet),
                const SizedBox(height: 16),
                _buildSummaryGrid(isWebWide, isTablet),
                const SizedBox(height: 18),
                tutorSectionTitle("Acciones rapidas"),
                const SizedBox(height: 12),
                _buildQuickActionsGrid(isWebWide, isTablet),
                const SizedBox(height: 18),
                tutorSectionTitle("Comentarios del maestro"),
                const SizedBox(height: 12),
                _buildCommentsList(),
                const SizedBox(height: 18),
                tutorSectionTitle("Reportes registrados"),
                const SizedBox(height: 12),
                _buildReportsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isTablet) {
    final now = DateTime.now();
    final dateText =
        "${tutorWeekdayEs(now.weekday)} ${now.day} ${tutorMonthEs(now.month)}";

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
            child: const Icon(
              Icons.family_restroom_rounded,
              color: TutorPalette.primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hola, ${_firstName(widget.username)}!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: TutorPalette.darkBlue,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Aqui tienes el panorama academico de ${_snapshot.studentName}.",
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

    final trailing = Column(
      crossAxisAlignment: isTablet
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
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
                dateText,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IconButton(
          tooltip: "Actualizar",
          onPressed: () => setState(() {}),
          icon: const Icon(
            Icons.refresh_rounded,
            color: TutorPalette.primaryBlue,
          ),
        ),
      ],
    );

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leadingBlock,
          const SizedBox(width: 12),
          trailing,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [leadingBlock]),
        const SizedBox(height: 14),
        trailing,
      ],
    );
  }

  Widget _buildHeroCard(bool isTablet) {
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
            "VISTA DEL TUTOR",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _snapshot.studentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Grupo ${_snapshot.groupName}  |  ${_snapshot.schoolPeriod}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Consulta calificaciones, asistencia, actividades y seguimiento del maestro desde un mismo tablero.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    final pills = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        _heroPill(
          icon: Icons.star_rounded,
          title: _snapshot.generalAverage.toStringAsFixed(1),
          subtitle: "Promedio",
        ),
        _heroPill(
          icon: Icons.how_to_reg_rounded,
          title: "${_snapshot.attendancePercentage.toStringAsFixed(0)}%",
          subtitle: "Asistencia",
        ),
        _heroPill(
          icon: Icons.assignment_rounded,
          title: "${_snapshot.reportsCount}",
          subtitle: "Reportes",
        ),
        _heroButton(),
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

  Widget _buildSummaryGrid(bool isWebWide, bool isTablet) {
    final items = [
      _DashboardMetric(
        value: _snapshot.generalAverage.toStringAsFixed(1),
        label: "Promedio general",
        detail: "Promedio acumulado actual",
        icon: Icons.auto_graph_rounded,
        tint: TutorPalette.primaryBlue,
      ),
      _DashboardMetric(
        value: "${_snapshot.totalAssistances}",
        label: "Total de asistencias",
        detail: "Registros confirmados",
        icon: Icons.fact_check_rounded,
        tint: TutorPalette.success,
      ),
      _DashboardMetric(
        value: "${_snapshot.totalAbsences}",
        label: "Total de faltas",
        detail: "Seguimiento puntual",
        icon: Icons.event_busy_rounded,
        tint: TutorPalette.danger,
      ),
      _DashboardMetric(
        value: "${_snapshot.assignedActivities}",
        label: "Actividades asignadas",
        detail: "${_snapshot.pendingActivitiesCount} pendientes",
        icon: Icons.assignment_outlined,
        tint: TutorPalette.warning,
      ),
      _DashboardMetric(
        value: "${_snapshot.teacherCommentsCount}",
        label: "Comentarios del maestro",
        detail: "Mensajes recientes",
        icon: Icons.chat_bubble_outline_rounded,
        tint: TutorPalette.info,
      ),
      _DashboardMetric(
        value: "${_snapshot.reportsCount}",
        label: "Reportes registrados",
        detail: "Academicos y de seguimiento",
        icon: Icons.description_outlined,
        tint: TutorPalette.violet,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWebWide ? 3 : (isTablet ? 2 : 1),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWebWide ? 2.2 : (isTablet ? 2.2 : 2.8),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return TutorMetricCard(
          value: item.value,
          label: item.label,
          detail: item.detail,
          icon: item.icon,
          tint: item.tint,
        );
      },
    );
  }

  Widget _buildQuickActionsGrid(bool isWebWide, bool isTablet) {
    final actions = [
      TutorActionCard(
        title: "Calificaciones",
        subtitle: "Promedio y parciales",
        icon: Icons.grade_rounded,
        tint: TutorPalette.primaryBlue,
        onTap: () => _openScreen(TutorGradesScreen(snapshot: _snapshot)),
      ),
      TutorActionCard(
        title: "Asistencia",
        subtitle: "Historial y porcentaje",
        icon: Icons.calendar_month_rounded,
        tint: TutorPalette.success,
        onTap: () => _openScreen(TutorAttendanceScreen(snapshot: _snapshot)),
      ),
      TutorActionCard(
        title: "Actividades",
        subtitle: "Pendientes y entregas",
        icon: Icons.assignment_rounded,
        tint: TutorPalette.warning,
        onTap: () => _openScreen(TutorActivitiesScreen(snapshot: _snapshot)),
      ),
      TutorActionCard(
        title: "Justificar faltas",
        subtitle: "Enviar aclaraciones",
        icon: Icons.approval_rounded,
        tint: TutorPalette.violet,
        onTap: () => _openScreen(
          TutorAbsenceJustificationScreen(snapshot: _snapshot),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWebWide ? 4 : (isTablet ? 2 : 1),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWebWide ? 1.35 : (isTablet ? 1.35 : 2.4),
      ),
      itemBuilder: (context, index) => actions[index],
    );
  }

  Widget _buildCommentsList() {
    return Column(
      children: _snapshot.comments.map((comment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _detailCard(
            icon: Icons.chat_bubble_outline_rounded,
            tint: TutorPalette.info,
            title: comment.subjectName,
            subtitle: comment.message,
            trailingTop: TutorStatusBadge(
              text: comment.dateLabel,
              color: TutorPalette.info,
            ),
            trailingBottom: Text(
              comment.author,
              style: const TextStyle(
                color: TutorPalette.textSoft,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportsList() {
    return Column(
      children: _snapshot.reports.map((report) {
        final statusColor = tutorStatusColor(report.status);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _detailCard(
            icon: Icons.description_outlined,
            tint: TutorPalette.violet,
            title: report.title,
            subtitle: report.summary,
            trailingTop: TutorStatusBadge(
              text: report.status,
              color: statusColor,
            ),
            trailingBottom: Text(
              report.dateLabel,
              style: const TextStyle(
                color: TutorPalette.textSoft,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _detailCard({
    required IconData icon,
    required Color tint,
    required String title,
    required String subtitle,
    required Widget trailingTop,
    required Widget trailingBottom,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: tutorSurfaceDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: TutorPalette.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TutorPalette.textSoft,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              trailingTop,
              const SizedBox(height: 8),
              trailingBottom,
            ],
          ),
        ],
      ),
    );
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

  Widget _heroButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _openScreen(TutorGradesScreen(snapshot: _snapshot)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              "Ver calificaciones",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  String _firstName(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      return "Tutor";
    }

    final first = clean.split(RegExp(r"\s+")).first;
    return first.isEmpty
        ? "Tutor"
        : "${first[0].toUpperCase()}${first.substring(1).toLowerCase()}";
  }
}

class _DashboardMetric {
  final String value;
  final String label;
  final String detail;
  final IconData icon;
  final Color tint;

  const _DashboardMetric({
    required this.value,
    required this.label,
    required this.detail,
    required this.icon,
    required this.tint,
  });
}
