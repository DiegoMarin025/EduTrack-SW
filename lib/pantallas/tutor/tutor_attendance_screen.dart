import 'package:flutter/material.dart';

import 'tutor_demo_data.dart';
import 'tutor_ui.dart';

class TutorAttendanceScreen extends StatelessWidget {
  final TutorStudentSnapshot snapshot;

  const TutorAttendanceScreen({
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
        title: const Text("Asistencia"),
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
                    icon: Icons.calendar_month_rounded,
                    title: "Asistencia de ${snapshot.studentName}",
                    subtitle:
                        "Revisa asistencias, faltas, porcentaje y el historial por fecha.",
                    trailing: _attendanceChip(),
                  ),
                  const SizedBox(height: 16),
                  _buildHeroCard(isTablet),
                  const SizedBox(height: 16),
                  _buildMetricsGrid(isWebWide, isTablet),
                  const SizedBox(height: 18),
                  tutorSectionTitle("Historial por fecha"),
                  const SizedBox(height: 12),
                  _buildHistoryList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _attendanceChip() {
    // Este contador depende hoy del fallback de justificaciones.
    // Cuando exista asistencia real por alumno, el snapshot debe llenar este valor.
    return TutorStatusBadge(
      text: "${snapshot.pendingJustificationsCount} por justificar",
      color: TutorPalette.warning,
    );
  }

  Widget _buildHeroCard(bool isTablet) {
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            "CONTROL DE ASISTENCIA",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "${snapshot.attendancePercentage.toStringAsFixed(1)}%",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Porcentaje acumulado del periodo actual con seguimiento por fecha.",
          style: TextStyle(
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
      children: [
        _heroPill(
          icon: Icons.fact_check_rounded,
          title: "${snapshot.totalAssistances}",
          subtitle: "Asistencias",
        ),
        _heroPill(
          icon: Icons.event_busy_rounded,
          title: "${snapshot.totalAbsences}",
          subtitle: "Faltas",
        ),
        _heroPill(
          icon: Icons.pending_actions_rounded,
          title: "${snapshot.pendingJustificationsCount}",
          subtitle: "Pendientes",
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
                  Expanded(child: detail),
                  const SizedBox(width: 14),
                  pills,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  detail,
                  const SizedBox(height: 16),
                  pills,
                ],
              ),
      ),
    );
  }

  Widget _buildMetricsGrid(bool isWebWide, bool isTablet) {
    // Totales y porcentaje todavia dependen del snapshot temporal.
    // Con Firebase se espera mapear asistencia/{fecha}/{alumnoId} hacia estos campos.
    final metrics = [
      TutorMetricCard(
        value: "${snapshot.totalAssistances}",
        label: "Total de asistencias",
        detail: "Presencias confirmadas",
        icon: Icons.check_circle_outline_rounded,
        tint: TutorPalette.success,
      ),
      TutorMetricCard(
        value: "${snapshot.totalAbsences}",
        label: "Total de faltas",
        detail: "Incidencias del periodo",
        icon: Icons.cancel_outlined,
        tint: TutorPalette.danger,
      ),
      TutorMetricCard(
        value: "${snapshot.attendancePercentage.toStringAsFixed(1)}%",
        label: "Porcentaje",
        detail: "Corte actual",
        icon: Icons.pie_chart_outline_rounded,
        tint: TutorPalette.primaryBlue,
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

  Widget _buildHistoryList() {
    // Historial por fecha: hoy es demo/fallback.
    // Cuando llegue la coleccion real, solo hay que reemplazar snapshot.attendanceHistory.
    if (snapshot.attendanceHistory.isEmpty) {
      return tutorEmptyStateCard(
        icon: Icons.calendar_month_rounded,
        title: "Aqui aparecera el historial de asistencia",
        message:
            "Cuando existan registros reales, veras asistencias, retardos y faltas por fecha en esta seccion.",
      );
    }

    return Column(
      children: snapshot.attendanceHistory.map((record) {
        final color = tutorStatusColor(record.status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: tutorSurfaceDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    record.status == "Falta"
                        ? Icons.event_busy_rounded
                        : Icons.today_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.dateLabel,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: TutorPalette.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        record.detail,
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
                TutorStatusBadge(text: record.status, color: color),
              ],
            ),
          ),
        );
      }).toList(),
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
}
