import 'package:flutter/material.dart';

import '../ayuda_screen.dart';
import 'tutor_absence_justification_screen.dart';
import 'tutor_demo_data.dart';
import 'tutor_live_data_service.dart';
import 'tutor_teacher_report_screen.dart';
import 'tutor_ui.dart';

class TutorCommunicationScreen extends StatefulWidget {
  final TutorStudentSnapshot initialSnapshot;
  final int userId;
  final String tutorName;

  const TutorCommunicationScreen({
    super.key,
    required this.initialSnapshot,
    required this.userId,
    required this.tutorName,
  });

  @override
  State<TutorCommunicationScreen> createState() =>
      _TutorCommunicationScreenState();
}

class _TutorCommunicationScreenState extends State<TutorCommunicationScreen> {
  late TutorStudentSnapshot _snapshot;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot;
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
        SnackBar(content: Text('No se pudo actualizar el seguimiento: $error')),
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
        title: const Text("Seguimiento al maestro"),
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
                      icon: Icons.forum_rounded,
                      title: "Seguimiento de ${_snapshot.studentName}",
                      subtitle:
                          "Consulta comentarios del maestro, justificaciones enviadas y reportes del tutor.",
                      trailing: TutorStatusBadge(
                        text:
                            "${_snapshot.comments.length + _snapshot.reports.length} registros",
                        color: TutorPalette.info,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHeroCard(isTablet),
                    const SizedBox(height: 16),
                    _buildMetricsGrid(isWebWide, isTablet),
                    const SizedBox(height: 18),
                    tutorSectionTitle("Acciones rapidas"),
                    const SizedBox(height: 12),
                    _buildQuickActions(isWebWide, isTablet),
                    const SizedBox(height: 18),
                    tutorSectionTitle("Comentarios del maestro"),
                    const SizedBox(height: 12),
                    _buildCommentsList(),
                    const SizedBox(height: 18),
                    tutorSectionTitle("Justificaciones enviadas"),
                    const SizedBox(height: 12),
                    _buildJustificationsList(),
                    const SizedBox(height: 18),
                    tutorSectionTitle("Reportes al maestro"),
                    const SizedBox(height: 12),
                    _buildReportsList(),
                  ],
                ),
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
            "COMUNICACION Y SEGUIMIENTO",
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
          _snapshot.studentName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _snapshot.schoolPeriod,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Desde aqui el tutor puede revisar lo que llega del maestro y tambien enviar justificaciones o reportes sin salir del flujo principal.",
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
      alignment: WrapAlignment.end,
      children: [
        _heroPill(
          icon: Icons.chat_bubble_outline_rounded,
          title: "${_snapshot.teacherCommentsCount}",
          subtitle: "Comentarios",
        ),
        _heroPill(
          icon: Icons.approval_rounded,
          title: "${_snapshot.justifications.length}",
          subtitle: "Justificaciones",
        ),
        _heroPill(
          icon: Icons.description_outlined,
          title: "${_snapshot.reportsCount}",
          subtitle: "Reportes",
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
                children: [details, const SizedBox(height: 16), pills],
              ),
      ),
    );
  }

  Widget _buildMetricsGrid(bool isWebWide, bool isTablet) {
    final metrics = [
      TutorMetricCard(
        value: "${_snapshot.teacherCommentsCount}",
        label: "Comentarios",
        detail: "Mensajes recientes del maestro",
        icon: Icons.chat_bubble_outline_rounded,
        tint: TutorPalette.info,
      ),
      TutorMetricCard(
        value: "${_snapshot.pendingJustificationsCount}",
        label: "Por justificar",
        detail: "Faltas pendientes de enviar",
        icon: Icons.pending_actions_rounded,
        tint: TutorPalette.warning,
      ),
      TutorMetricCard(
        value: "${_snapshot.justifications.length}",
        label: "Justificaciones",
        detail: "Historial del tutor",
        icon: Icons.approval_rounded,
        tint: TutorPalette.violet,
      ),
      TutorMetricCard(
        value: "${_snapshot.reportsCount}",
        label: "Reportes",
        detail: "Seguimientos enviados al maestro",
        icon: Icons.description_outlined,
        tint: TutorPalette.primaryBlue,
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

  Widget _buildQuickActions(bool isWebWide, bool isTablet) {
    final actions = [
      TutorActionCard(
        title: "Justificar faltas",
        subtitle: "Enviar aclaraciones",
        icon: Icons.approval_rounded,
        tint: TutorPalette.violet,
        onTap: () => _openScreen(
          TutorAbsenceJustificationScreen(
            snapshot: _snapshot,
            userId: widget.userId,
            tutorName: widget.tutorName,
          ),
        ),
      ),
      TutorActionCard(
        title: "Nuevo reporte",
        subtitle: "Enviar seguimiento",
        icon: Icons.campaign_rounded,
        tint: TutorPalette.info,
        onTap: () => _openScreen(
          TutorTeacherReportScreen(snapshot: _snapshot, userId: widget.userId),
        ),
      ),
      TutorActionCard(
        title: "Ayuda",
        subtitle: "Soporte del sistema",
        icon: Icons.help_outline_rounded,
        tint: TutorPalette.success,
        onTap: () => _openScreen(const AyudaScreen()),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWebWide ? 3 : (isTablet ? 2 : 1),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWebWide ? 1.55 : (isTablet ? 1.5 : 2.4),
      ),
      itemBuilder: (context, index) => actions[index],
    );
  }

  Widget _buildCommentsList() {
    if (_snapshot.comments.isEmpty) {
      return tutorEmptyStateCard(
        icon: Icons.chat_bubble_outline_rounded,
        title: "Aqui apareceran los comentarios del maestro",
        message:
            "Cuando el maestro capture observaciones o retroalimentacion del alumno, las veras en esta seccion.",
      );
    }

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

  Widget _buildJustificationsList() {
    if (_snapshot.justifications.isEmpty) {
      return tutorEmptyStateCard(
        icon: Icons.approval_rounded,
        title: "Aqui apareceran las justificaciones",
        message:
            "Cuando el tutor envie o tenga faltas por justificar, el historial aparecera en esta seccion.",
      );
    }

    return Column(
      children: _snapshot.justifications.map((record) {
        final color = tutorStatusColor(record.status);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _detailCard(
            icon: Icons.approval_rounded,
            tint: TutorPalette.violet,
            title: "${record.subjectName} | ${record.reason}",
            subtitle: record.detail,
            extraContent: record.hasAttachment
                ? _buildAttachmentInfo(
                    fileName: record.attachmentName,
                    sizeBytes: record.attachmentSizeBytes,
                  )
                : null,
            trailingTop: TutorStatusBadge(text: record.status, color: color),
            trailingBottom: Text(
              record.dateLabel,
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
    if (_snapshot.reports.isEmpty) {
      return tutorEmptyStateCard(
        icon: Icons.description_outlined,
        title: "Aqui apareceran los reportes enviados",
        message:
            "Los reportes academicos o de seguimiento que mande el tutor se mostraran aqui.",
      );
    }

    return Column(
      children: _snapshot.reports.map((report) {
        final color = tutorStatusColor(report.status);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _detailCard(
            icon: Icons.description_outlined,
            tint: TutorPalette.primaryBlue,
            title: report.title,
            subtitle: report.summary,
            extraContent: report.hasAttachment
                ? _buildAttachmentInfo(
                    fileName: report.attachmentName,
                    sizeBytes: report.attachmentSizeBytes,
                  )
                : null,
            trailingTop: TutorStatusBadge(text: report.status, color: color),
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
    Widget? extraContent,
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
                if (extraContent != null) ...[
                  const SizedBox(height: 10),
                  extraContent,
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [trailingTop, const SizedBox(height: 8), trailingBottom],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentInfo({
    required String fileName,
    required int sizeBytes,
  }) {
    final safeName = fileName.trim().isNotEmpty ? fileName : 'Adjunto enviado';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TutorPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: TutorPalette.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.attach_file_rounded,
              color: TutorPalette.primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w800,
                    color: TutorPalette.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sizeBytes > 0
                      ? 'Adjunto enviado | ${_formatAttachmentSize(sizeBytes)}'
                      : 'Adjunto enviado',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TutorPalette.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAttachmentSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openScreen(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (result == true && mounted) {
      _refreshSnapshot();
    }
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
