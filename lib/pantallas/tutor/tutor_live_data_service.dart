import 'package:shared_preferences/shared_preferences.dart';

import '../../pantallas/materia_models.dart';
import '../../services/api_service.dart';
import '../../services/report_attachment_picker.dart';
import '../../services/asistencia_service.dart';
import 'tutor_demo_data.dart';

class TutorLiveDataService {
  static Future<TutorStudentSnapshot> loadSnapshot({
    required int sessionUserId,
    required String tutorName,
  }) async {
    final fallback = buildTutorDemoData(tutorName: tutorName);
    final prefs = await SharedPreferences.getInstance();
    final sessionRole = (prefs.getString('saved_userType') ?? '')
        .trim()
        .toLowerCase();

    TutorAlumnoVinculado? linkedStudent;
    int? linkedStudentId = prefs.getInt('saved_linked_student_id');

    if (sessionRole == 'tutor') {
      try {
        linkedStudent = await ApiService.getTutorAlumnoVinculado(sessionUserId);
        linkedStudentId = linkedStudent?.id ?? linkedStudentId;
        if (linkedStudentId != null && linkedStudentId > 0) {
          await prefs.setInt('saved_linked_student_id', linkedStudentId);
        }
      } catch (_) {}
    }

    final alumnoId = sessionRole == 'tutor' ? linkedStudentId : sessionUserId;
    if (alumnoId == null || alumnoId <= 0) {
      return fallback;
    }

    DashboardData? dashboard;
    Map<String, List<Materia>> historial = {};
    List<TutorReporteMaestro> tutorReports = [];
    List<AsistenciaAlumnoHistorialItem> attendanceItems = [];
    final summariesByClass = <int, ResumenFinalAlumno>{};

    try {
      dashboard = await ApiService.getStudentDashboard(alumnoId);
    } catch (_) {}

    try {
      historial = await ApiService.getHistorialAcademico(alumnoId);
    } catch (_) {}

    if (sessionRole == 'tutor') {
      try {
        tutorReports = await ApiService.getTutorReportes(sessionUserId);
      } catch (_) {}
    }

    try {
      attendanceItems = await AsistenciaService.obtenerHistorialPorAlumno(
        alumnoId,
      );
    } catch (_) {}

    if (dashboard != null && dashboard.subjects.isNotEmpty) {
      final entries = await Future.wait<MapEntry<int, ResumenFinalAlumno>?>(
        dashboard.subjects.map((subject) async {
          try {
            final summary = await ApiService.getResumenFinalAlumno(
              claseId: subject.claseId,
              alumnoId: alumnoId,
            );
            return MapEntry(subject.claseId, summary);
          } catch (_) {
            return null;
          }
        }),
      );

      for (final entry in entries) {
        if (entry != null) {
          summariesByClass[entry.key] = entry.value;
        }
      }
    }

    final latestGroupName = _resolveLatestGroupName(historial);
    final todasLasMaterias = _collectAllMaterias(historial);
    final subjectNameByClassId = _buildSubjectNameByClassId(dashboard);
    final teacherBySubject = _buildTeacherBySubject(todasLasMaterias);
    final attendanceTotals = _countAttendance(attendanceItems);

    final grades = _buildGrades(
      materias: todasLasMaterias,
      teacherBySubject: teacherBySubject,
      subjectNameByClassId: subjectNameByClassId,
      summariesByClass: summariesByClass,
      dashboard: dashboard,
      fallback: fallback.grades,
    );

    final comments = _buildComments(
      materiasActuales: todasLasMaterias,
      teacherBySubject: teacherBySubject,
      subjectNameByClassId: subjectNameByClassId,
      summariesByClass: summariesByClass,
      fallback: fallback.comments,
    );

    final reports = _buildReports(
      tutorReports: tutorReports,
      fallback: fallback.reports,
    );

    final activities = _buildActivities(
      materiasActuales: todasLasMaterias,
      subjectNameByClassId: subjectNameByClassId,
      summariesByClass: summariesByClass,
      fallback: fallback.activities,
    );

    final attendanceHistory = _buildAttendanceHistory(attendanceItems);
    final justifications = _buildJustifications(
      attendanceItems: attendanceItems,
      tutorReports: tutorReports,
    );

    final studentName =
        dashboard?.student.nombre ??
        linkedStudent?.nombre ??
        fallback.studentName;

    final groupName =
        latestGroupName != null &&
            latestGroupName.trim().isNotEmpty &&
            latestGroupName.trim().toLowerCase() != 'sin grupo'
        ? latestGroupName.trim()
        : fallback.groupName;

    return TutorStudentSnapshot(
      tutorName: tutorName,
      studentName: studentName,
      groupName: groupName,
      schoolPeriod: _buildIdentityLabel(
        alumnoId: alumnoId,
        dashboard: dashboard,
        linkedStudent: linkedStudent,
      ),
      totalAssistances: attendanceTotals.assistances,
      totalAbsences: attendanceTotals.absences,
      grades: grades.isNotEmpty ? grades : fallback.grades,
      comments: comments.isNotEmpty ? comments : fallback.comments,
      reports: reports.isNotEmpty ? reports : fallback.reports,
      activities: activities.isNotEmpty ? activities : fallback.activities,
      attendanceHistory: attendanceHistory.isNotEmpty
          ? attendanceHistory
          : fallback.attendanceHistory,
      justifications: justifications.isNotEmpty
          ? justifications
          : fallback.justifications,
    );
  }

  static Future<bool> submitTeacherReport({
    required int userId,
    required String category,
    required String title,
    required String detail,
    String? subjectName,
    SelectedReportAttachment? attachment,
  }) async {
    try {
      await ApiService.enviarReporteTutorMaestro(
        tutorId: userId,
        categoria: category,
        titulo: title,
        mensaje: detail,
        materia: subjectName,
        attachment: attachment,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> submitAbsenceJustification({
    required int usuarioId,
    required TutorJustificationRecord record,
    required String reason,
    required String detail,
    SelectedReportAttachment? attachment,
  }) async {
    final subjectName = record.subjectName.trim();
    final subjectLabel = subjectName.isNotEmpty
        ? subjectName
        : 'Sin materia especifica';
    final message = [
      'TIPO: Justificacion de falta.',
      'FECHA: ${record.dateLabel}',
      'MATERIA: $subjectLabel',
      'MOTIVO: $reason',
      'DETALLE: $detail',
    ].join('\n');

    return submitTeacherReport(
      userId: usuarioId,
      category: 'Justificacion de falta',
      title: subjectName.isNotEmpty
          ? 'Justificacion de falta | $subjectName'
          : 'Justificacion de falta',
      detail: message,
      subjectName: subjectName.isNotEmpty ? subjectName : null,
      attachment: attachment,
    );
  }

  static TutorSubjectGrade _mapMateriaToGrade(
    Materia materia, {
    ResumenFinalAlumno? summary,
  }) {
    final gradePoints = summary != null
        ? _gradePointsFromSummary(summary)
        : _gradePointsFromMateria(materia);
    final average = _resolveAverageForMateria(
      materia,
      summary,
      fallbackPoints: gradePoints,
    );

    final teacherNote = summary?.ultimoComentario.trim().isNotEmpty == true
        ? summary!.ultimoComentario.trim()
        : _buildTeacherNote(materia);

    return TutorSubjectGrade(
      subjectName: materia.nombre,
      teacherName: materia.profesor,
      teacherNote: teacherNote,
      average: average ?? 0,
      partials: gradePoints.map((item) => item.score).toList(),
      evaluationLabels: gradePoints.map((item) => item.label).toList(),
      hasRecordedAverage: average != null,
      progressLabel: _buildProgressLabel(
        average: average,
        evaluationCount: gradePoints.length,
      ),
      trackedItemsCount: materia.evaluaciones.length,
    );
  }

  static List<TutorSubjectGrade> _buildGrades({
    required List<Materia> materias,
    required Map<String, String> teacherBySubject,
    required Map<int, String> subjectNameByClassId,
    required Map<int, ResumenFinalAlumno> summariesByClass,
    required DashboardData? dashboard,
    required List<TutorSubjectGrade> fallback,
  }) {
    final grades = <TutorSubjectGrade>[];
    final seen = <String>{};

    for (final entry in summariesByClass.entries) {
      final subjectName =
          subjectNameByClassId[entry.key]?.trim().isNotEmpty == true
          ? subjectNameByClassId[entry.key]!.trim()
          : 'Materia';
      final subjectKey = _subjectKey(subjectName);
      final materia = _findMateriaBySubject(materias, subjectName);
      final summary = entry.value;
      final gradePoints = _gradePointsFromSummary(summary);
      final average = _resolveAverageForMateria(
        materia,
        summary,
        fallbackPoints: gradePoints,
      );

      grades.add(
        TutorSubjectGrade(
          subjectName: subjectName,
          teacherName:
              materia?.profesor ??
              teacherBySubject[subjectKey] ??
              'Docente asignado',
          teacherNote: summary.ultimoComentario.trim().isNotEmpty
              ? summary.ultimoComentario.trim()
              : (materia != null
                    ? _buildTeacherNote(materia)
                    : _subjectNote(
                        subjectName,
                        average ?? 0,
                        _statusFromAverage(average),
                      )),
          average: average ?? 0,
          partials: gradePoints.map((item) => item.score).toList(),
          evaluationLabels: gradePoints.map((item) => item.label).toList(),
          hasRecordedAverage: average != null,
          progressLabel: _buildProgressLabel(
            average: average,
            evaluationCount: gradePoints.length,
            hasTrackedActivities: summary.totalActividades > 0,
          ),
          trackedItemsCount: summary.totalActividades,
        ),
      );
      seen.add(subjectKey);
    }

    for (final materia in materias) {
      final subjectKey = _subjectKey(materia.nombre);
      if (!seen.add(subjectKey)) {
        continue;
      }

      grades.add(_mapMateriaToGrade(materia, summary: null));
    }

    if (grades.isNotEmpty) {
      return _sortGrades(grades);
    }

    return _mapDashboardSubjects(dashboard, summariesByClass, fallback);
  }

  static List<TutorSubjectGrade> _mapDashboardSubjects(
    DashboardData? dashboard,
    Map<int, ResumenFinalAlumno> summariesByClass,
    List<TutorSubjectGrade> fallback,
  ) {
    if (dashboard == null || dashboard.subjects.isEmpty) {
      return fallback;
    }

    return _sortGrades(
      dashboard.subjects.map((subject) {
        final summary = summariesByClass[subject.claseId];
        final gradePoints = summary != null
            ? _gradePointsFromSummary(summary)
            : _gradePointsFromSubject(subject);
        final average =
            _normalizeNullableGrade(summary?.calificacionFinal) ??
            _normalizeNullableGrade(summary?.calificacionSugerida) ??
            _normalizeNullableGrade(summary?.promedioActividades) ??
            _normalizeNullableGrade(subject.calificacion) ??
            _averageFromPoints(gradePoints);

        return TutorSubjectGrade(
          subjectName: subject.materia,
          teacherName: 'Docente asignado',
          teacherNote: summary?.ultimoComentario.trim().isNotEmpty == true
              ? summary!.ultimoComentario.trim()
              : _subjectNote(subject.materia, average ?? 0, subject.estado),
          average: average ?? 0,
          partials: gradePoints.map((item) => item.score).toList(),
          evaluationLabels: gradePoints.map((item) => item.label).toList(),
          hasRecordedAverage: average != null,
          progressLabel: _buildProgressLabel(
            average: average,
            evaluationCount: gradePoints.length,
            hasTrackedActivities: subject.totalActividades > 0,
          ),
          trackedItemsCount: subject.totalActividades,
        );
      }).toList(),
    );
  }

  static List<TutorTeacherComment> _buildComments({
    required List<Materia> materiasActuales,
    required Map<String, String> teacherBySubject,
    required Map<int, String> subjectNameByClassId,
    required Map<int, ResumenFinalAlumno> summariesByClass,
    required List<TutorTeacherComment> fallback,
  }) {
    final comments = <_TimedComment>[];
    final seen = <String>{};

    for (final entry in summariesByClass.entries) {
      final subjectName =
          subjectNameByClassId[entry.key]?.trim().isNotEmpty == true
          ? subjectNameByClassId[entry.key]!.trim()
          : 'Materia';
      final author =
          teacherBySubject[_subjectKey(subjectName)] ?? 'Maestro de grupo';
      var addedComment = false;

      for (final activity in entry.value.actividades) {
        final message = activity.comentario.trim();
        if (message.isEmpty) {
          continue;
        }

        final dedupeKey = '${_subjectKey(subjectName)}|$message';
        if (!seen.add(dedupeKey)) {
          continue;
        }

        comments.add(
          _TimedComment(
            sortDate: _sortDateOrEpoch(activity.fechaEntrega),
            value: TutorTeacherComment(
              subjectName: subjectName,
              author: author,
              message: message,
              dateLabel: activity.fechaEntrega.trim().isNotEmpty
                  ? _formatDateLabel(activity.fechaEntrega)
                  : 'Revision reciente',
            ),
          ),
        );
        addedComment = true;
      }

      final latestComment = entry.value.ultimoComentario.trim();
      if (!addedComment && latestComment.isNotEmpty) {
        final dedupeKey = '${_subjectKey(subjectName)}|$latestComment';
        if (seen.add(dedupeKey)) {
          comments.add(
            _TimedComment(
              sortDate: DateTime.fromMillisecondsSinceEpoch(0),
              value: TutorTeacherComment(
                subjectName: subjectName,
                author: author,
                message: latestComment,
                dateLabel: 'Comentario reciente',
              ),
            ),
          );
        }
      }
    }

    for (final materia in materiasActuales) {
      final latestComment = _latestCommentForMateria(materia);
      if (latestComment == null || latestComment.comentario.trim().isEmpty) {
        continue;
      }

      final message = latestComment.comentario.trim();
      final dedupeKey = '${_subjectKey(materia.nombre)}|$message';
      if (!seen.add(dedupeKey)) {
        continue;
      }

      comments.add(
        _TimedComment(
          sortDate: _sortDateOrEpoch(latestComment.fecha),
          value: TutorTeacherComment(
            subjectName: materia.nombre,
            author: materia.profesor,
            message: message,
            dateLabel: latestComment.fecha.trim().isNotEmpty
                ? _formatDateLabel(latestComment.fecha)
                : (materia.semestre.trim().isNotEmpty
                      ? materia.semestre
                      : 'Actual'),
          ),
        ),
      );
    }

    comments.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    if (comments.isNotEmpty) {
      return comments.take(5).map((item) => item.value).toList();
    }

    return fallback;
  }

  static List<TutorReportRecord> _buildReports({
    required List<TutorReporteMaestro> tutorReports,
    required List<TutorReportRecord> fallback,
  }) {
    final reports = <_TimedReport>[
      ...tutorReports.map(
        (item) => _TimedReport(
          sortDate: _sortDateOrEpoch(item.fecha),
          value: _mapTutorReportToRecord(item),
        ),
      ),
    ];

    reports.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return reports.isNotEmpty
        ? reports.take(6).map((item) => item.value).toList()
        : fallback;
  }

  static List<TutorActivityRecord> _buildActivities({
    required List<Materia> materiasActuales,
    required Map<int, String> subjectNameByClassId,
    required Map<int, ResumenFinalAlumno> summariesByClass,
    required List<TutorActivityRecord> fallback,
  }) {
    final activities = <_TimedActivity>[];
    final seen = <String>{};

    for (final entry in summariesByClass.entries) {
      final subjectName =
          subjectNameByClassId[entry.key]?.trim().isNotEmpty == true
          ? subjectNameByClassId[entry.key]!.trim()
          : 'Materia';

      for (final activity in entry.value.actividades) {
        final title = activity.titulo.trim();
        if (title.isEmpty) {
          continue;
        }

        final dedupeKey = '${_subjectKey(subjectName)}|${_subjectKey(title)}';
        if (!seen.add(dedupeKey)) {
          continue;
        }

        activities.add(
          _TimedActivity(
            sortDate: _sortDateOrEpoch(activity.fechaEntrega),
            value: TutorActivityRecord(
              title: title,
              subjectName: subjectName,
              dueDateLabel: activity.fechaEntrega.trim().isNotEmpty
                  ? _formatDateLabel(activity.fechaEntrega)
                  : 'Sin fecha',
              status: _normalizeActivityStatus(activity.estado),
              description: _buildSummaryActivityDescription(activity),
            ),
          ),
        );
      }
    }

    for (final materia in materiasActuales) {
      for (final evaluacion in materia.evaluaciones) {
        final title = evaluacion.nombre.trim();
        if (title.isEmpty) {
          continue;
        }

        final dedupeKey =
            '${_subjectKey(materia.nombre)}|${_subjectKey(title)}';
        if (!seen.add(dedupeKey)) {
          continue;
        }

        final delivered = (evaluacion.calificacion ?? 0) > 0;
        activities.add(
          _TimedActivity(
            sortDate: _sortDateOrEpoch(evaluacion.fecha),
            value: TutorActivityRecord(
              title: title,
              subjectName: materia.nombre,
              dueDateLabel: evaluacion.fecha.trim().isNotEmpty
                  ? _formatDateLabel(evaluacion.fecha)
                  : (materia.semestre.trim().isNotEmpty
                        ? materia.semestre
                        : 'Sin fecha'),
              status: delivered ? 'Entregada' : 'Pendiente',
              description: _buildLegacyActivityDescription(evaluacion),
            ),
          ),
        );
      }
    }

    activities.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return activities.isNotEmpty
        ? activities.take(12).map((item) => item.value).toList()
        : fallback;
  }

  static List<TutorAttendanceRecord> _buildAttendanceHistory(
    List<AsistenciaAlumnoHistorialItem> attendanceItems,
  ) {
    return attendanceItems.map((item) {
      final note = item.detalle.nota.trim();
      final parts = <String>[
        if (item.registro.grupoNombre.trim().isNotEmpty)
          item.registro.grupoNombre.trim(),
        if (item.registro.materia.trim().isNotEmpty)
          item.registro.materia.trim(),
        if (note.isNotEmpty) note,
      ];

      return TutorAttendanceRecord(
        dateLabel: _formatDateLabel(item.registro.fecha.toIso8601String()),
        status: _attendanceStatusLabel(item.detalle.estado),
        detail: parts.isNotEmpty
            ? parts.join(' | ')
            : 'Registro de asistencia del maestro',
      );
    }).toList();
  }

  static List<TutorJustificationRecord> _buildJustifications({
    required List<AsistenciaAlumnoHistorialItem> attendanceItems,
    required List<TutorReporteMaestro> tutorReports,
  }) {
    final records = <String, TutorJustificationRecord>{};

    for (final item in attendanceItems) {
      if (item.detalle.estado != EstadoAsistencia.ausente) {
        continue;
      }

      final dateLabel = _formatDateLabel(item.registro.fecha.toIso8601String());
      final subjectName = item.registro.materia.trim().isNotEmpty
          ? item.registro.materia.trim()
          : 'Materia';
      final note = item.detalle.nota.trim();
      final key = '${dateLabel.toLowerCase()}|${subjectName.toLowerCase()}';

      records[key] = TutorJustificationRecord(
        dateLabel: dateLabel,
        subjectName: subjectName,
        status: 'Pendiente',
        reason: note.isNotEmpty ? note : 'Pendiente de justificar',
        detail: _buildAttendanceJustificationDetail(item),
      );
    }

    for (final report in tutorReports) {
      if (report.categoria.trim().toLowerCase() != 'justificacion de falta') {
        continue;
      }

      final fields = _parseJustificationFields(report.mensaje);
      final rawDate = fields['fecha']?.trim().isNotEmpty == true
          ? fields['fecha']!.trim()
          : report.fecha;
      final subjectName = fields['materia']?.trim().isNotEmpty == true
          ? fields['materia']!.trim()
          : (report.materia.trim().isNotEmpty
                ? report.materia.trim()
                : 'Materia');
      final reason = fields['motivo']?.trim().isNotEmpty == true
          ? fields['motivo']!.trim()
          : 'Justificacion enviada';
      final detail = fields['detalle']?.trim().isNotEmpty == true
          ? fields['detalle']!.trim()
          : report.mensaje.trim();
      final dateLabel = _formatDateLabel(rawDate);
      final key = '${dateLabel.toLowerCase()}|${subjectName.toLowerCase()}';

      records[key] = TutorJustificationRecord(
        dateLabel: dateLabel,
        subjectName: subjectName,
        status: _normalizeJustificationStatus(report.estado),
        reason: reason,
        detail: detail,
        attachmentName: report.adjuntoNombre,
        attachmentUrl: report.adjuntoUrl,
        attachmentSizeBytes: report.adjuntoTamano,
      );
    }

    final ordered = records.values.toList()
      ..sort(
        (a, b) => _sortDateOrEpoch(
          b.dateLabel,
        ).compareTo(_sortDateOrEpoch(a.dateLabel)),
      );
    return ordered;
  }

  static TutorTeacherComment _mapMateriaToComment(Materia materia) {
    final latestComment = _latestCommentForMateria(materia);

    return TutorTeacherComment(
      subjectName: materia.nombre,
      author: materia.profesor,
      message: latestComment?.comentario.trim().isNotEmpty == true
          ? latestComment!.comentario.trim()
          : _subjectNote(
              materia.nombre,
              materia.calificacionFinal,
              materia.estatus,
            ),
      dateLabel: latestComment?.fecha.trim().isNotEmpty == true
          ? _formatDateLabel(latestComment!.fecha)
          : (materia.semestre.trim().isNotEmpty ? materia.semestre : 'Actual'),
    );
  }

  static TutorReportRecord _mapTutorReportToRecord(TutorReporteMaestro item) {
    final subjectSuffix = item.materia.trim().isNotEmpty
        ? ' | ${item.materia}'
        : '';
    final summaryPrefix = item.categoria.trim().isNotEmpty
        ? '${item.categoria}: '
        : '';

    return TutorReportRecord(
      title: '${item.titulo}$subjectSuffix',
      summary: '$summaryPrefix${item.mensaje}',
      status: _normalizeJustificationStatus(item.estado),
      dateLabel: _formatDateLabel(item.fecha),
      attachmentName: item.adjuntoNombre,
      attachmentUrl: item.adjuntoUrl,
      attachmentSizeBytes: item.adjuntoTamano,
    );
  }

  static Evaluacion? _latestCommentForMateria(Materia materia) {
    final evaluations = List<Evaluacion>.from(materia.evaluaciones)
      ..sort(
        (a, b) =>
            _sortDateOrEpoch(b.fecha).compareTo(_sortDateOrEpoch(a.fecha)),
      );

    for (final evaluacion in evaluations) {
      if (evaluacion.comentario.trim().isNotEmpty) {
        return evaluacion;
      }
    }
    return null;
  }

  static String _buildTeacherNote(Materia materia) {
    final latestComment = _latestCommentForMateria(materia);
    if (latestComment != null && latestComment.comentario.trim().isNotEmpty) {
      return latestComment.comentario.trim();
    }

    return _subjectNote(
      materia.nombre,
      materia.calificacionFinal,
      materia.estatus,
    );
  }

  static double? _resolveAverageForMateria(
    Materia? materia,
    ResumenFinalAlumno? summary, {
    required List<_GradePoint> fallbackPoints,
  }) {
    final summaryAverage =
        _normalizeNullableGrade(summary?.calificacionFinal) ??
        _normalizeNullableGrade(summary?.calificacionSugerida) ??
        _normalizeNullableGrade(summary?.promedioActividades);

    if (summaryAverage != null) {
      return summaryAverage;
    }

    if (materia != null) {
      final overrideAverage = _normalizeNullableGrade(
        materia.calificacionFinalOverride,
      );
      final hasRecordedItems =
          fallbackPoints.isNotEmpty ||
          materia.evaluaciones.any((item) => item.calificacion != null);
      if (overrideAverage != null &&
          (overrideAverage > 0 || hasRecordedItems)) {
        return overrideAverage;
      }
    }

    if (fallbackPoints.isNotEmpty) {
      return _averageFromPoints(fallbackPoints);
    }

    return null;
  }

  static String _subjectNote(String subject, double average, String status) {
    if (status == 'En Curso') {
      return 'La materia $subject sigue en curso y aun se estan consolidando evaluaciones.';
    }
    if (average >= 9) {
      return 'Excelente avance en $subject. Conviene mantener el ritmo y la participacion.';
    }
    if (average >= 7) {
      return 'Buen progreso en $subject. Un poco mas de constancia puede subir el promedio.';
    }
    return 'Se recomienda reforzar $subject con acompanamiento y repaso adicional.';
  }

  static String _statusFromAverage(double? average) {
    if (average == null) {
      return 'En Curso';
    }
    return average >= 7 ? 'Aprobada' : 'Reprobada';
  }

  static Map<int, String> _buildSubjectNameByClassId(DashboardData? dashboard) {
    if (dashboard == null) {
      return const <int, String>{};
    }

    return {
      for (final subject in dashboard.subjects)
        subject.claseId: subject.materia,
    };
  }

  static Map<String, String> _buildTeacherBySubject(List<Materia> materias) {
    return {
      for (final materia in materias)
        _subjectKey(materia.nombre): materia.profesor.trim().isNotEmpty
            ? materia.profesor.trim()
            : 'Docente asignado',
    };
  }

  static List<Materia> _collectAllMaterias(
    Map<String, List<Materia>> historial,
  ) {
    final materias = <Materia>[];

    for (final entry in historial.values) {
      materias.addAll(entry);
    }

    return materias;
  }

  static Materia? _findMateriaBySubject(
    List<Materia> materias,
    String subject,
  ) {
    final key = _subjectKey(subject);

    for (final materia in materias) {
      if (_subjectKey(materia.nombre) == key) {
        return materia;
      }
    }

    return null;
  }

  static List<_GradePoint> _gradePointsFromMateria(Materia materia) {
    return materia.evaluaciones
        .where((item) => item.calificacion != null)
        .map(
          (item) => _GradePoint(
            label: item.nombre.trim().isNotEmpty
                ? item.nombre.trim()
                : 'Evaluacion',
            score: item.calificacion!.clamp(0, 10).toDouble(),
          ),
        )
        .toList();
  }

  static List<_GradePoint> _gradePointsFromSummary(ResumenFinalAlumno summary) {
    return summary.actividades
        .where((item) => item.calificacion != null)
        .map(
          (item) => _GradePoint(
            label: item.titulo.trim().isNotEmpty
                ? item.titulo.trim()
                : 'Evaluacion',
            score: item.calificacion!.clamp(0, 10).toDouble(),
          ),
        )
        .toList();
  }

  static List<_GradePoint> _gradePointsFromSubject(Subject subject) {
    return subject.actividades
        .where((item) => item.calificacion != null)
        .map(
          (item) => _GradePoint(
            label: item.titulo.trim().isNotEmpty
                ? item.titulo.trim()
                : 'Evaluacion',
            score: item.calificacion!.clamp(0, 10).toDouble(),
          ),
        )
        .toList();
  }

  static double? _normalizeNullableGrade(double? value) {
    if (value == null) {
      return null;
    }

    return value.clamp(0, 10).toDouble();
  }

  static double? _averageFromPoints(List<_GradePoint> points) {
    if (points.isEmpty) {
      return null;
    }

    final total = points.fold<double>(0, (sum, item) => sum + item.score);
    return (total / points.length).clamp(0, 10).toDouble();
  }

  static String _buildProgressLabel({
    required double? average,
    required int evaluationCount,
    bool hasTrackedActivities = false,
  }) {
    if (average == null) {
      return evaluationCount > 0 || hasTrackedActivities
          ? 'En seguimiento'
          : 'Sin evaluar';
    }

    if (average >= 9) {
      return 'Excelente avance';
    }
    if (average >= 7) {
      return 'Buen avance';
    }
    return 'Requiere apoyo';
  }

  static List<TutorSubjectGrade> _sortGrades(List<TutorSubjectGrade> grades) {
    final ordered = List<TutorSubjectGrade>.from(grades);
    ordered.sort((left, right) {
      if (left.hasRecordedAverage != right.hasRecordedAverage) {
        return left.hasRecordedAverage ? -1 : 1;
      }

      if (left.hasRecordedAverage && right.hasRecordedAverage) {
        return right.average.compareTo(left.average);
      }

      return left.subjectName.toLowerCase().compareTo(
        right.subjectName.toLowerCase(),
      );
    });
    return ordered;
  }

  static _AttendanceTotals _countAttendance(
    List<AsistenciaAlumnoHistorialItem> attendanceItems,
  ) {
    var assistances = 0;
    var absences = 0;

    for (final item in attendanceItems) {
      if (item.detalle.estado == EstadoAsistencia.ausente) {
        absences++;
      } else {
        assistances++;
      }
    }

    return _AttendanceTotals(assistances: assistances, absences: absences);
  }

  static String? _resolveLatestGroupName(Map<String, List<Materia>> historial) {
    if (historial.isEmpty) {
      return null;
    }

    for (final key in historial.keys) {
      final clean = key.trim();
      if (clean.isNotEmpty && clean.toLowerCase() != 'sin grupo') {
        return clean;
      }
    }

    return historial.keys.first.trim();
  }

  static String _buildIdentityLabel({
    required int alumnoId,
    DashboardData? dashboard,
    TutorAlumnoVinculado? linkedStudent,
  }) {
    final rawId = dashboard?.student.matricula.trim().isNotEmpty == true
        ? dashboard!.student.matricula.trim()
        : (linkedStudent?.id.toString() ?? alumnoId.toString());
    return 'ID $rawId';
  }

  static String _buildSummaryActivityDescription(
    ActividadFinalDetalle activity,
  ) {
    final parts = <String>[];
    final description = activity.descripcion.trim();
    final comment = activity.comentario.trim();

    if (description.isNotEmpty) {
      parts.add(description);
    }
    if (activity.valor > 0) {
      parts.add('Vale ${_formatNumericValue(activity.valor)}');
    }
    if (activity.calificacion != null) {
      parts.add('Calificacion ${activity.calificacion!.toStringAsFixed(1)}');
    }
    if (comment.isNotEmpty) {
      parts.add('Comentario: ${_truncate(comment, 80)}');
    }

    return parts.isNotEmpty
        ? parts.join(' | ')
        : 'Actividad registrada por el maestro.';
  }

  static String _buildLegacyActivityDescription(Evaluacion evaluacion) {
    final parts = <String>[];
    final comment = evaluacion.comentario.trim();

    if (evaluacion.peso > 0) {
      parts.add('Peso ${_formatNumericValue(evaluacion.peso)}%');
    }
    if (evaluacion.calificacion != null) {
      parts.add('Calificacion ${evaluacion.calificacion!.toStringAsFixed(1)}');
    }
    if (comment.isNotEmpty) {
      parts.add('Comentario: ${_truncate(comment, 80)}');
    }

    return parts.isNotEmpty
        ? parts.join(' | ')
        : 'Seguimiento academico del maestro.';
  }

  static String _buildAttendanceJustificationDetail(
    AsistenciaAlumnoHistorialItem item,
  ) {
    final note = item.detalle.nota.trim();
    final parts = <String>[
      'Grupo ${item.registro.grupoNombre}',
      item.registro.materia,
    ];

    if (note.isNotEmpty) {
      parts.add('Nota del maestro: $note');
    } else {
      parts.add('Falta registrada por el maestro');
    }

    return parts.where((part) => part.trim().isNotEmpty).join(' | ');
  }

  static Map<String, String> _parseJustificationFields(String message) {
    final fields = <String, String>{};

    for (final rawLine in message.split('\n')) {
      final line = rawLine.trim();
      final separatorIndex = line.indexOf(':');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = line.substring(0, separatorIndex).trim().toLowerCase();
      final value = line.substring(separatorIndex + 1).trim();
      fields[key] = value;
    }

    return fields;
  }

  static String _normalizeActivityStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'calificado':
      case 'entregado':
        return 'Entregada';
      case 'no entregado':
      case 'sin revisar':
        return 'Pendiente';
      default:
        return 'Pendiente';
    }
  }

  static String _normalizeJustificationStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'aprobado':
      case 'aprobada':
        return 'Aprobada';
      case 'enviado':
      case 'en revision':
      case 'en revision':
        return 'En revision';
      default:
        return status.trim().isEmpty ? 'Pendiente' : status;
    }
  }

  static String _attendanceStatusLabel(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.ausente:
        return 'Falta';
      case EstadoAsistencia.retardo:
        return 'Retardo';
      case EstadoAsistencia.presente:
        return 'Asistencia';
    }
  }

  static String _subjectKey(String value) {
    return value.trim().toLowerCase();
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength - 3)}...';
  }

  static String _formatNumericValue(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  static DateTime _sortDateOrEpoch(String rawDate) {
    return _parseDate(rawDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseDate(String rawDate) {
    final clean = rawDate.trim();
    if (clean.isEmpty) {
      return null;
    }

    return DateTime.tryParse(clean);
  }

  static String _formatDateLabel(String rawDate) {
    final parsed = _parseDate(rawDate);
    if (parsed == null) {
      return rawDate;
    }

    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return '${parsed.day} ${months[(parsed.month - 1).clamp(0, 11)]}';
  }
}

class _TimedComment {
  final DateTime sortDate;
  final TutorTeacherComment value;

  const _TimedComment({required this.sortDate, required this.value});
}

class _TimedReport {
  final DateTime sortDate;
  final TutorReportRecord value;

  const _TimedReport({required this.sortDate, required this.value});
}

class _TimedActivity {
  final DateTime sortDate;
  final TutorActivityRecord value;

  const _TimedActivity({required this.sortDate, required this.value});
}

class _GradePoint {
  final String label;
  final double score;

  const _GradePoint({required this.label, required this.score});
}

class _AttendanceTotals {
  final int assistances;
  final int absences;

  const _AttendanceTotals({required this.assistances, required this.absences});
}
