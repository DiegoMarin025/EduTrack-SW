import 'package:shared_preferences/shared_preferences.dart';

import '../../pantallas/materia_models.dart';
import '../../services/api_service.dart';
import 'tutor_demo_data.dart';

class TutorLiveDataService {
  static Future<TutorStudentSnapshot> loadSnapshot({
    required int alumnoId,
    required String tutorName,
  }) async {
    // Respaldo temporal para todo lo que aun no existe en backend/Firebase
    // para tutor: asistencia historica, faltas reales, justificaciones y
    // algunas actividades/comentarios.
    final fallback = buildTutorDemoData(tutorName: tutorName);

    DashboardData? dashboard;
    Map<String, List<Materia>> historial = {};
    List<Notificacion> notificaciones = [];

    try {
      // Fuente real existente del antiguo flujo de alumno.
      dashboard = await ApiService.getStudentDashboard(alumnoId);
    } catch (_) {}

    try {
      // Fuente real con materias/evaluaciones para construir calificaciones.
      historial = await ApiService.getHistorialAcademico(alumnoId);
    } catch (_) {}

    try {
      // Fuente real aprovechada como "reportes" temporales.
      notificaciones = await ApiService.getNotificaciones(alumnoId);
    } catch (_) {}

    final latestSemester = historial.keys.isNotEmpty
        ? historial.keys.first
        : fallback.schoolPeriod;
    final materiasActuales = historial[latestSemester] ?? const <Materia>[];

    final grades = materiasActuales.isNotEmpty
        ? materiasActuales.map(_mapMateriaToGrade).toList()
        : _mapDashboardSubjects(dashboard, fallback.grades);

    final comments = materiasActuales.isNotEmpty
        ? materiasActuales.take(3).map(_mapMateriaToComment).toList()
        : fallback.comments;

    final reports = notificaciones.isNotEmpty
        ? notificaciones.take(5).map(_mapNotificationToReport).toList()
        : fallback.reports;

    final activities = materiasActuales.isNotEmpty
        ? _buildActivities(materiasActuales, fallback.activities)
        : fallback.activities;

    // Ojo: el dashboard actual no expone grupo como tal. Por ahora se reutiliza
    // matricula/campo disponible si viene del backend; si despues existe grupo real,
    // mapearlo aqui.
    final liveGroupName = dashboard != null && dashboard.student.matricula.isNotEmpty
        ? dashboard.student.matricula
        : fallback.groupName;

    return TutorStudentSnapshot(
      tutorName: tutorName,
      studentName: dashboard?.student.nombre ?? fallback.studentName,
      groupName: liveGroupName,
      schoolPeriod: latestSemester,
      // TODO tutor/Firebase: sustituir estos campos cuando exista asistencia real
      // en backend o colecciones dedicadas.
      totalAssistances: fallback.totalAssistances,
      totalAbsences: fallback.totalAbsences,
      grades: grades.isNotEmpty ? grades : fallback.grades,
      comments: comments.isNotEmpty ? comments : fallback.comments,
      reports: reports.isNotEmpty ? reports : fallback.reports,
      activities: activities.isNotEmpty ? activities : fallback.activities,
      // TODO tutor/Firebase: conectar historial por fecha y justificaciones reales.
      attendanceHistory: fallback.attendanceHistory,
      justifications: fallback.justifications,
    );
  }

  static Future<bool> submitAbsenceJustification({
    required int usuarioId,
    required TutorJustificationRecord record,
    required String reason,
    required String detail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email =
          prefs.getString('saved_username') ??
          prefs.getString('correo') ??
          'usuario@edutrack.app';

      final message = [
        'TIPO: Justificacion de falta.',
        'FECHA: ${record.dateLabel}',
        'MATERIA: ${record.subjectName}',
        'MOTIVO: $reason',
        'DETALLE: $detail',
      ].join('\n');

      // Salida temporal: mientras no exista una coleccion propia de justificaciones,
      // se usa el endpoint actual de soporte para no perder el envio del tutor.
      // Cuando se migre a Firebase, reemplazar esta llamada por create/update del
      // documento de justificacion conservando esta firma.
      await ApiService.enviarReporteSoporte(usuarioId, email, message);
      return true;
    } catch (_) {
      return false;
    }
  }

  static TutorSubjectGrade _mapMateriaToGrade(Materia materia) {
    // Si la materia no trae parciales reales, se estiman 3 valores para no romper
    // la UI actual de calificaciones. Reemplazar por parciales reales cuando existan.
    final partials = materia.evaluaciones.isNotEmpty
        ? materia.evaluaciones
              .take(3)
              .map<double>(
                (item) => item.calificacion.clamp(0, 10).toDouble(),
              )
              .toList()
        : _estimatedPartials(materia.calificacionFinal);

    while (partials.length < 3) {
      partials.add(materia.calificacionFinal.clamp(0, 10).toDouble());
    }

    return TutorSubjectGrade(
      subjectName: materia.nombre,
      teacherName: materia.profesor,
      teacherNote: _subjectNote(
        materia.nombre,
        materia.calificacionFinal,
        materia.estatus,
      ),
      average: materia.calificacionFinal,
      partials: partials.take(3).toList(),
    );
  }

  static List<TutorSubjectGrade> _mapDashboardSubjects(
    DashboardData? dashboard,
    List<TutorSubjectGrade> fallback,
  ) {
    if (dashboard == null || dashboard.subjects.isEmpty) {
      return fallback;
    }

    return dashboard.subjects.map((subject) {
      final average = (subject.calificacion ?? 0).clamp(0, 10).toDouble();
      return TutorSubjectGrade(
        subjectName: subject.materia,
        teacherName: "Docente asignado",
        teacherNote: _subjectNote(subject.materia, average, subject.estado),
        average: average,
        partials: _estimatedPartials(average),
      );
    }).toList();
  }

  static TutorTeacherComment _mapMateriaToComment(Materia materia) {
    return TutorTeacherComment(
      subjectName: materia.nombre,
      author: materia.profesor,
      message: _subjectNote(
        materia.nombre,
        materia.calificacionFinal,
        materia.estatus,
      ),
      dateLabel: materia.semestre.isNotEmpty ? materia.semestre : "Actual",
    );
  }

  static TutorReportRecord _mapNotificationToReport(Notificacion item) {
    return TutorReportRecord(
      title: item.titulo,
      summary: item.mensaje,
      status: item.leida ? "Registrado" : "En revision",
      dateLabel: _formatDateLabel(item.fecha),
    );
  }

  static List<TutorActivityRecord> _buildActivities(
    List<Materia> materias,
    List<TutorActivityRecord> fallback,
  ) {
    final activities = <TutorActivityRecord>[];

    for (final materia in materias) {
      if (materia.evaluaciones.isEmpty) {
        // Placeholder controlado: la materia existe, pero aun no hay tareas separadas.
        activities.add(
          TutorActivityRecord(
            title: "Seguimiento de ${materia.nombre}",
            subjectName: materia.nombre,
            dueDateLabel: materia.semestre.isNotEmpty
                ? materia.semestre
                : "Sin fecha en backend",
            status: "Pendiente",
            description:
                "Aun no hay actividades detalladas sincronizadas para esta materia.",
          ),
        );
        continue;
      }

      for (final evaluacion in materia.evaluaciones.take(3)) {
        // Aproximacion temporal: cada evaluacion del historial se muestra como actividad.
        // Si luego hay una coleccion real "actividades", construirlas desde esa fuente.
        final delivered = evaluacion.calificacion > 0;
        activities.add(
          TutorActivityRecord(
            title: evaluacion.nombre,
            subjectName: materia.nombre,
            dueDateLabel: materia.semestre.isNotEmpty
                ? materia.semestre
                : "Sin fecha en backend",
            status: delivered ? "Entregada" : "Pendiente",
            description:
                "Peso ${evaluacion.peso.toStringAsFixed(0)}% - Calificacion ${evaluacion.calificacion.toStringAsFixed(1)}.",
          ),
        );
      }
    }

    return activities.isNotEmpty ? activities : fallback;
  }

  static List<double> _estimatedPartials(double average) {
    final base = average.clamp(0, 10).toDouble();
    return [
      (base - 0.3).clamp(0, 10).toDouble(),
      base,
      (base + 0.2).clamp(0, 10).toDouble(),
    ];
  }

  static String _subjectNote(String subject, double average, String status) {
    if (status == "En Curso") {
      return "La materia $subject sigue en curso y aun se estan consolidando evaluaciones.";
    }
    if (average >= 9) {
      return "Excelente avance en $subject. Conviene mantener el ritmo y la participacion.";
    }
    if (average >= 7) {
      return "Buen progreso en $subject. Un poco mas de constancia puede subir el promedio.";
    }
    return "Se recomienda reforzar $subject con acompanamiento y repaso adicional.";
  }

  static String _formatDateLabel(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) {
      return rawDate;
    }

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

    return "${parsed.day} ${months[(parsed.month - 1).clamp(0, 11)]}";
  }
}
