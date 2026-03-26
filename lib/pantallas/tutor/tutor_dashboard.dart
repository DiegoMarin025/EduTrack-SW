import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tutor_absence_justification_screen.dart';
import 'tutor_activities_screen.dart';
import 'tutor_attendance_screen.dart';
import 'tutor_communication_screen.dart';
import 'tutor_demo_data.dart';
import 'tutor_grades_screen.dart';
import 'tutor_live_data_service.dart';
import 'tutor_teacher_report_screen.dart';
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
  late TutorStudentSnapshot _snapshot;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _snapshot = buildTutorDemoData(tutorName: widget.username, studentId: widget.userId);
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    setState(() => _syncing = true);
    final loaded = await TutorLiveDataService.loadSnapshot(
      sessionUserId: widget.userId,
      tutorName: widget.username,
    );
    if (!mounted) return;
    setState(() {
      _snapshot = loaded;
      _syncing = false;
    });
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
          constraints: BoxConstraints(maxWidth: isWebWide ? 1120 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWebWide ? 28 : 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(isTablet),
                const SizedBox(height: 16),
                _buildHeroCard(isTablet),
                const SizedBox(height: 16),
                _buildSummaryGrid(isWebWide, isTablet), // 🟢 TU GRID RESTAURADO
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

  // 🟢 LA CUADRÍCULA SEGURA (6 TARJETAS EXACTAS Y BLINDADAS)
  Widget _buildSummaryGrid(bool isWebWide, bool isTablet) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWebWide ? 3 : (isTablet ? 2 : 1),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWebWide ? 2.2 : (isTablet ? 2.2 : 2.8),
      ),
      children: [
        // 1. PROMEDIO GENERAL
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('calificaciones').where('alumnoId', isEqualTo: _snapshot.studentId).snapshots(),
          builder: (context, snapshot) {
            String value = "0.0";
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              double suma = 0;
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                suma += double.tryParse(data['calificacion'].toString()) ?? 0.0;
              }
              value = (suma / snapshot.data!.docs.length).toStringAsFixed(1);
            }
            return TutorMetricCard(value: value, label: "Promedio general", detail: "Promedio real", icon: Icons.auto_graph_rounded, tint: TutorPalette.primaryBlue);
          },
        ),

        // 2. ASISTENCIAS (Con Escudo Anti-Errores)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('asistencias').snapshots(),
          builder: (context, snapshot) {
            int asistencias = 0;
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>?; // 🛡️ Escudo
                if (data != null && data.containsKey('detalles')) {
                  final detalles = data['detalles'] as List<dynamic>? ?? [];
                  final registro = detalles.firstWhere((d) => d['alumnoId'] == _snapshot.studentId, orElse: () => null);
                  if (registro != null && registro['estado'].toString().toLowerCase() == 'presente') {
                    asistencias++;
                  }
                }
              }
            }
            return TutorMetricCard(value: "$asistencias", label: "Total de asistencias", detail: "Días presente", icon: Icons.fact_check_rounded, tint: TutorPalette.success);
          },
        ),

        // 3. FALTAS (Con Escudo Anti-Errores)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('asistencias').snapshots(),
          builder: (context, snapshot) {
            int faltas = 0;
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>?; // 🛡️ Escudo
                if (data != null && data.containsKey('detalles')) {
                  final detalles = data['detalles'] as List<dynamic>? ?? [];
                  final registro = detalles.firstWhere((d) => d['alumnoId'] == _snapshot.studentId, orElse: () => null);
                  if (registro != null && registro['estado'].toString().toLowerCase() == 'falta') {
                    faltas++;
                  }
                }
              }
            }
            return TutorMetricCard(value: "$faltas", label: "Total de faltas", detail: "Inasistencias", icon: Icons.event_busy_rounded, tint: TutorPalette.danger);
          },
        ),

        // 4. ACTIVIDADES 
        TutorMetricCard(value: "${_snapshot.assignedActivities}", label: "Actividades asignadas", detail: "${_snapshot.pendingActivitiesCount} pendientes", icon: Icons.assignment_outlined, tint: TutorPalette.warning),

        // 5. JUSTIFICANTES
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('justificantes').where('alumnoId', isEqualTo: _snapshot.studentId).snapshots(),
          builder: (context, snapshot) {
            int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return TutorMetricCard(value: "$total", label: "Justificantes", detail: "Enviados al docente", icon: Icons.approval_rounded, tint: TutorPalette.info);
          },
        ),

        // 6. REPORTES
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reportes_seguimiento').where('alumnoId', isEqualTo: _snapshot.studentId).snapshots(),
          builder: (context, snapshot) {
            int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return TutorMetricCard(value: "$total", label: "Reportes enviados", detail: "A autoridades", icon: Icons.description_outlined, tint: TutorPalette.violet);
          },
        ),
      ],
    );
  }

  // --- TUS MÉTODOS DE DISEÑO INTACTOS ---

  Widget _buildTopHeader(bool isTablet) {
    final now = DateTime.now();
    final dateText = "${tutorWeekdayEs(now.weekday)} ${now.day} ${tutorMonthEs(now.month)}";
    final leadingBlock = Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: TutorPalette.primaryBlue.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.family_restroom_rounded, color: TutorPalette.primaryBlue, size: 26)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Hola, ${_firstName(widget.username)}!", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: TutorPalette.darkBlue, height: 1.1)), const SizedBox(height: 6), Text("Aqui tienes el panorama academico de ${_snapshot.studentName}.", style: const TextStyle(color: TutorPalette.textSoft, fontSize: 14, fontWeight: FontWeight.w500))])),
    ]));

    final trailing = Column(crossAxisAlignment: isTablet ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: TutorPalette.border)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.calendar_month_rounded, size: 18, color: TutorPalette.primaryBlue), const SizedBox(width: 8), Text(dateText, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)))])),
      const SizedBox(height: 10),
      IconButton(tooltip: "Actualizar", onPressed: _syncing ? null : _loadSnapshot, icon: _syncing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TutorPalette.primaryBlue)) : const Icon(Icons.refresh_rounded, color: TutorPalette.primaryBlue)),
    ]);

    if (isTablet) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [leadingBlock, const SizedBox(width: 12), trailing]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [leadingBlock]), const SizedBox(height: 14), trailing]);
  }

  Widget _buildHeroCard(bool isTablet) {
    final assignedTeacher = _buildAssignedTeacherLabel();
    final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)), child: const Text("VISTA DEL TUTOR", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6))),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.school_rounded, color: Colors.white, size: 30)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_snapshot.studentName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 6),
          Text(_buildStudentMetaLine(), style: const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w600)),
          if (assignedTeacher != null) ...[const SizedBox(height: 8), Row(children: [const Icon(Icons.person_rounded, size: 16, color: Colors.white70), const SizedBox(width: 6), Expanded(child: Text("Maestro asignado: $assignedTeacher", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)))])],
          const SizedBox(height: 10),
        ])),
      ]),
    ]);

    final pills = Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.end, children: [
      // Promedio en el Header
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('calificaciones').where('alumnoId', isEqualTo: _snapshot.studentId).snapshots(),
        builder: (context, snapshot) {
          String value = "0.0";
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            double suma = 0;
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              suma += double.tryParse(data['calificacion'].toString()) ?? 0.0;
            }
            value = (suma / snapshot.data!.docs.length).toStringAsFixed(1);
          }
          return _heroPill(icon: Icons.star_rounded, title: value, subtitle: "Promedio");
        },
      ),
      // Asistencia en el Header
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('asistencias').snapshots(),
        builder: (context, snapshot) {
          int asis = 0; int faltas = 0;
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data != null && data.containsKey('detalles')) {
                final detalles = data['detalles'] as List<dynamic>? ?? [];
                final registro = detalles.firstWhere((d) => d['alumnoId'] == _snapshot.studentId, orElse: () => null);
                if (registro != null) {
                  if (registro['estado'].toString().toLowerCase() == 'presente') asis++;
                  if (registro['estado'].toString().toLowerCase() == 'falta') faltas++;
                }
              }
            }
          }
          double perc = (asis + faltas == 0) ? 0 : (asis / (asis + faltas)) * 100;
          return _heroPill(icon: Icons.how_to_reg_rounded, title: "${perc.toStringAsFixed(0)}%", subtitle: "Asistencia");
        }
      ),
      _heroButton(),
    ]);

    return Container(
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [TutorPalette.primaryBlue, TutorPalette.darkBlue], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: TutorPalette.primaryBlue.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 10))]),
      child: Padding(padding: const EdgeInsets.all(18), child: isTablet ? Row(children: [Expanded(child: details), const SizedBox(width: 14), pills]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [details, const SizedBox(height: 16), pills])),
    );
  }

  Widget _buildQuickActionsGrid(bool isWebWide, bool isTablet) {
    final actions = [
      TutorActionCard(title: "Calificaciones", subtitle: "Promedio y notas", icon: Icons.grade_rounded, tint: TutorPalette.primaryBlue, onTap: () => _openScreen(TutorGradesScreen(snapshot: _snapshot, userId: widget.userId, tutorName: widget.username))),
      TutorActionCard(title: "Asistencia", subtitle: "Faltas y porcentaje", icon: Icons.calendar_month_rounded, tint: TutorPalette.success, onTap: () => _openScreen(TutorAttendanceScreen(snapshot: _snapshot, userId: widget.userId, tutorName: widget.username))),
      TutorActionCard(title: "Actividades", subtitle: "Tareas pendientes", icon: Icons.assignment_rounded, tint: TutorPalette.warning, onTap: () => _openScreen(TutorActivitiesScreen(snapshot: _snapshot))),
      TutorActionCard(title: "Mensajes", subtitle: "Comunicación docente", icon: Icons.forum_rounded, tint: TutorPalette.info, onTap: () => _openScreen(TutorCommunicationScreen(initialSnapshot: _snapshot, userId: widget.userId, tutorName: widget.username))),
      TutorActionCard(title: "Justificantes", subtitle: "Aclarar faltas", icon: Icons.approval_rounded, tint: TutorPalette.violet, onTap: () => _openScreen(TutorAbsenceJustificationScreen(snapshot: _snapshot, userId: widget.userId, tutorName: widget.username))),
      TutorActionCard(title: "Reportar", subtitle: "Enviar incidencia", icon: Icons.campaign_rounded, tint: TutorPalette.danger, onTap: () => _openScreen(TutorTeacherReportScreen(snapshot: _snapshot, userId: widget.userId))), 
    ];

    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: actions.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isWebWide ? 4 : (isTablet ? 2 : 1), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: isWebWide ? 1.35 : (isTablet ? 1.35 : 2.4)), itemBuilder: (context, index) => actions[index]);
  }

  Widget _buildCommentsList() {
    if (_snapshot.comments.isEmpty) return tutorEmptyStateCard(icon: Icons.chat_bubble_outline_rounded, title: "Sin comentarios aún", message: "Los mensajes del profesor aparecerán aquí.");
    return Column(children: _snapshot.comments.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _detailCard(icon: Icons.chat_bubble_outline, tint: TutorPalette.info, title: c.subjectName, subtitle: c.message, trailingTop: TutorStatusBadge(text: c.dateLabel, color: TutorPalette.info), trailingBottom: Text(c.author, style: const TextStyle(color: TutorPalette.textSoft, fontSize: 12.5, fontWeight: FontWeight.w700))))).toList());
  }

  Widget _buildReportsList() {
    if (_snapshot.reports.isEmpty) return tutorEmptyStateCard(icon: Icons.description_outlined, title: "No hay reportes recientes", message: "El historial de reportes de este alumno está limpio.");
    return Column(children: _snapshot.reports.map((r) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _detailCard(icon: Icons.description_outlined, tint: TutorPalette.violet, title: r.title, subtitle: r.summary, trailingTop: TutorStatusBadge(text: r.status, color: tutorStatusColor(r.status)), trailingBottom: Text(r.dateLabel, style: const TextStyle(color: TutorPalette.textSoft, fontSize: 12.5, fontWeight: FontWeight.w700))))).toList());
  }

  Widget _detailCard({required IconData icon, required Color tint, required String title, required String subtitle, required Widget trailingTop, required Widget trailingBottom}) {
    return Container(padding: const EdgeInsets.all(16), decoration: tutorSurfaceDecoration(), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: tint.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: tint, size: 24)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: TutorPalette.textDark)), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TutorPalette.textSoft, height: 1.45))])), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [trailingTop, const SizedBox(height: 8), trailingBottom])]));
  }

  Widget _heroPill({required IconData icon, required String title, required String subtitle}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.14))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600))])]));
  }

  Widget _heroButton() {
    return InkWell(borderRadius: BorderRadius.circular(999), onTap: () => _openScreen(TutorGradesScreen(snapshot: _snapshot, userId: widget.userId, tutorName: widget.username)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.18))), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18), SizedBox(width: 6), Text("Ver calificaciones", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))])));
  }

  Future<void> _openScreen(Widget screen) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (result == true && mounted) _loadSnapshot();
  }

  String _firstName(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return "Tutor";
    final first = clean.split(RegExp(r"\s+")).first;
    return first.isEmpty ? "Tutor" : "${first[0].toUpperCase()}${first.substring(1).toLowerCase()}";
  }

  String _buildStudentMetaLine() {
    final parts = <String>[];
    final groupName = _snapshot.groupName.trim();
    final identity = _snapshot.schoolPeriod.trim();
    if (groupName.isNotEmpty && groupName.toLowerCase() != "pendiente") parts.add("Grupo $groupName");
    if (identity.isNotEmpty && identity.toLowerCase() != "sin informacion academica") parts.add(identity);
    return parts.isNotEmpty ? parts.join("  |  ") : "Alumno vinculado";
  }

  String? _buildAssignedTeacherLabel() {
    final counts = <String, int>{};
    void registerName(String rawValue) {
      final clean = rawValue.trim();
      final normalized = clean.toLowerCase();
      if (clean.isEmpty || normalized == 'docente asignado' || normalized == 'sin docente asignado') return;
      counts.update(clean, (value) => value + 1, ifAbsent: () => 1);
    }
    for (final grade in _snapshot.grades) registerName(grade.teacherName);
    for (final comment in _snapshot.comments) registerName(comment.author);
    if (counts.isEmpty) return null;
    final ranked = counts.entries.toList()..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return a.key.toLowerCase().compareTo(b.key.toLowerCase());
    });
    return ranked.first.key;
  }
}