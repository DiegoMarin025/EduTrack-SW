import 'package:flutter/material.dart';

import 'tutor_demo_data.dart';
import 'tutor_ui.dart';

class TutorActivitiesScreen extends StatelessWidget {
  final TutorStudentSnapshot snapshot;

  const TutorActivitiesScreen({
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
        title: const Text("Actividades"),
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
                    icon: Icons.assignment_rounded,
                    title: "Actividades de ${snapshot.studentName}",
                    subtitle:
                        "Revisa las actividades asignadas, su materia y la fecha de entrega.",
                    trailing: TutorStatusBadge(
                      text: "${snapshot.pendingActivitiesCount} pendientes",
                      color: TutorPalette.warning,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHeroCard(isTablet),
                  const SizedBox(height: 16),
                  _buildMetricsGrid(isWebWide, isTablet),
                  const SizedBox(height: 18),
                  tutorSectionTitle("Lista de actividades"),
                  const SizedBox(height: 12),
                  _buildActivitiesList(),
                ],
              ),
            ),
          ),
        ),
      ),
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
            "SEGUIMIENTO DE TAREAS",
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
          "${snapshot.assignedActivities}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Total de actividades asignadas para el periodo actual con control de estatus.",
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
          icon: Icons.pending_actions_rounded,
          title: "${snapshot.pendingActivitiesCount}",
          subtitle: "Pendientes",
        ),
        _heroPill(
          icon: Icons.check_circle_rounded,
          title: "${snapshot.deliveredActivitiesCount}",
          subtitle: "Entregadas",
        ),
        _heroPill(
          icon: Icons.class_rounded,
          title: "${snapshot.grades.length}",
          subtitle: "Materias",
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
        value: "${snapshot.assignedActivities}",
        label: "Actividades asignadas",
        detail: "Total del tablero",
        icon: Icons.assignment_outlined,
        tint: TutorPalette.primaryBlue,
      ),
      TutorMetricCard(
        value: "${snapshot.pendingActivitiesCount}",
        label: "Pendientes",
        detail: "Por entregar o revisar",
        icon: Icons.schedule_rounded,
        tint: TutorPalette.warning,
      ),
      TutorMetricCard(
        value: "${snapshot.deliveredActivitiesCount}",
        label: "Entregadas",
        detail: "Registradas como completas",
        icon: Icons.task_alt_rounded,
        tint: TutorPalette.success,
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

  Widget _buildActivitiesList() {
    return Column(
      children: snapshot.activities.map((activity) {
        final statusColor = tutorStatusColor(activity.status);

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
                        Icons.assignment_turned_in_rounded,
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
                            activity.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: TutorPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            activity.subjectName,
                            style: const TextStyle(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w700,
                              color: TutorPalette.textSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TutorStatusBadge(
                      text: activity.status,
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TutorPalette.textSoft,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
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
                        Icons.event_note_rounded,
                        size: 18,
                        color: TutorPalette.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Fecha de entrega: ${activity.dueDateLabel}",
                        style: const TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                          color: TutorPalette.textDark,
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
