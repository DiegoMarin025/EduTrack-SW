class TutorStudentSnapshot {
  final String tutorName;
  final String studentName;
  final String groupName;
  final String schoolPeriod;
  final int totalAssistances;
  final int totalAbsences;
  final List<TutorSubjectGrade> grades;
  final List<TutorTeacherComment> comments;
  final List<TutorReportRecord> reports;
  final List<TutorActivityRecord> activities;
  final List<TutorAttendanceRecord> attendanceHistory;
  final List<TutorJustificationRecord> justifications;

  const TutorStudentSnapshot({
    required this.tutorName,
    required this.studentName,
    required this.groupName,
    required this.schoolPeriod,
    required this.totalAssistances,
    required this.totalAbsences,
    required this.grades,
    required this.comments,
    required this.reports,
    required this.activities,
    required this.attendanceHistory,
    required this.justifications,
  });

  double get generalAverage {
    if (grades.isEmpty) {
      return 0;
    }

    final total = grades.fold<double>(0, (sum, item) => sum + item.average);
    return total / grades.length;
  }

  double get attendancePercentage {
    final total = totalAssistances + totalAbsences;
    if (total == 0) {
      return 0;
    }

    return (totalAssistances / total) * 100;
  }

  int get assignedActivities => activities.length;

  int get pendingActivitiesCount =>
      activities.where((item) => item.status != "Entregada").length;

  int get deliveredActivitiesCount =>
      activities.where((item) => item.status == "Entregada").length;

  int get teacherCommentsCount => comments.length;

  int get reportsCount => reports.length;

  int get pendingJustificationsCount =>
      justifications.where((item) => item.status == "Pendiente").length;

  int get approvedJustificationsCount =>
      justifications.where((item) => item.status == "Aprobada").length;

  TutorSubjectGrade get strongestSubject {
    return grades.reduce((current, next) {
      return current.average >= next.average ? current : next;
    });
  }
}

class TutorSubjectGrade {
  final String subjectName;
  final String teacherName;
  final String teacherNote;
  final double average;
  final List<double> partials;

  const TutorSubjectGrade({
    required this.subjectName,
    required this.teacherName,
    required this.teacherNote,
    required this.average,
    required this.partials,
  });
}

class TutorTeacherComment {
  final String subjectName;
  final String author;
  final String message;
  final String dateLabel;

  const TutorTeacherComment({
    required this.subjectName,
    required this.author,
    required this.message,
    required this.dateLabel,
  });
}

class TutorReportRecord {
  final String title;
  final String summary;
  final String status;
  final String dateLabel;

  const TutorReportRecord({
    required this.title,
    required this.summary,
    required this.status,
    required this.dateLabel,
  });
}

class TutorActivityRecord {
  final String title;
  final String subjectName;
  final String dueDateLabel;
  final String status;
  final String description;

  const TutorActivityRecord({
    required this.title,
    required this.subjectName,
    required this.dueDateLabel,
    required this.status,
    required this.description,
  });
}

class TutorAttendanceRecord {
  final String dateLabel;
  final String status;
  final String detail;

  const TutorAttendanceRecord({
    required this.dateLabel,
    required this.status,
    required this.detail,
  });
}

class TutorJustificationRecord {
  final String dateLabel;
  final String subjectName;
  final String status;
  final String reason;
  final String detail;

  const TutorJustificationRecord({
    required this.dateLabel,
    required this.subjectName,
    required this.status,
    required this.reason,
    required this.detail,
  });

  TutorJustificationRecord copyWith({
    String? dateLabel,
    String? subjectName,
    String? status,
    String? reason,
    String? detail,
  }) {
    return TutorJustificationRecord(
      dateLabel: dateLabel ?? this.dateLabel,
      subjectName: subjectName ?? this.subjectName,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      detail: detail ?? this.detail,
    );
  }
}

TutorStudentSnapshot buildTutorDemoData({
  required String tutorName,
}) {
  const grades = [
    TutorSubjectGrade(
      subjectName: "Matematicas aplicadas",
      teacherName: "Mtra. Laura Vega",
      teacherNote:
          "Participa bien y resuelve ejercicios con seguridad. Conviene reforzar algebra en casa.",
      average: 9.5,
      partials: [9.2, 9.7, 9.6],
    ),
    TutorSubjectGrade(
      subjectName: "Fisica industrial",
      teacherName: "Ing. Daniel Soto",
      teacherNote:
          "Mantiene constancia. Cuando entrega practicas completas mejora bastante su resultado final.",
      average: 8.8,
      partials: [8.4, 8.7, 9.3],
    ),
    TutorSubjectGrade(
      subjectName: "Programacion movil",
      teacherName: "Mtro. Sergio Neri",
      teacherNote:
          "Es una de sus materias mas fuertes. Tiene buen criterio y entrega a tiempo.",
      average: 9.7,
      partials: [9.5, 9.8, 9.9],
    ),
    TutorSubjectGrade(
      subjectName: "Ingles tecnico",
      teacherName: "Miss Karla Ruiz",
      teacherNote:
          "Va bien en lectura y vocabulario. Se recomienda practicar speaking para subir un poco mas.",
      average: 8.9,
      partials: [8.6, 8.8, 9.2],
    ),
  ];

  const comments = [
    TutorTeacherComment(
      subjectName: "Programacion movil",
      author: "Mtro. Sergio Neri",
      message:
          "Diego participo activamente en clase y ayudo a su equipo a cerrar la practica.",
      dateLabel: "18 Mar",
    ),
    TutorTeacherComment(
      subjectName: "Fisica industrial",
      author: "Ing. Daniel Soto",
      message:
          "Necesita revisar formulas antes del laboratorio. Su actitud en clase es positiva.",
      dateLabel: "16 Mar",
    ),
    TutorTeacherComment(
      subjectName: "Ingles tecnico",
      author: "Miss Karla Ruiz",
      message:
          "Mostro avance en comprension lectora y respondio correctamente la actividad de seguimiento.",
      dateLabel: "14 Mar",
    ),
  ];

  const reports = [
    TutorReportRecord(
      title: "Reporte academico mensual",
      summary:
          "Se observo avance sostenido en materias tecnicas y mejor organizacion de tareas.",
      status: "Registrado",
      dateLabel: "12 Mar",
    ),
    TutorReportRecord(
      title: "Seguimiento de asistencia",
      summary:
          "Se registro una falta durante la segunda semana del mes. No hay incidencias graves.",
      status: "En revision",
      dateLabel: "08 Mar",
    ),
  ];

  const activities = [
    TutorActivityRecord(
      title: "Proyecto de interfaz final",
      subjectName: "Programacion movil",
      dueDateLabel: "24 Mar 2026",
      status: "Pendiente",
      description:
          "Crear una propuesta visual con componentes reutilizables y navegacion funcional.",
    ),
    TutorActivityRecord(
      title: "Bitacora de laboratorio",
      subjectName: "Fisica industrial",
      dueDateLabel: "25 Mar 2026",
      status: "Pendiente",
      description:
          "Registrar observaciones del experimento y anexar conclusiones de equipo.",
    ),
    TutorActivityRecord(
      title: "Ejercicios de derivadas",
      subjectName: "Matematicas aplicadas",
      dueDateLabel: "19 Mar 2026",
      status: "Entregada",
      description:
          "Serie corta de problemas de practica con procedimiento completo.",
    ),
    TutorActivityRecord(
      title: "Vocabulary checkpoint",
      subjectName: "Ingles tecnico",
      dueDateLabel: "21 Mar 2026",
      status: "En revision",
      description:
          "Actividad breve para repasar vocabulario tecnico de clase.",
    ),
  ];

  const attendanceHistory = [
    TutorAttendanceRecord(
      dateLabel: "20 Mar 2026",
      status: "Asistencia",
      detail: "Ingreso puntual y completo la jornada sin incidencias.",
    ),
    TutorAttendanceRecord(
      dateLabel: "19 Mar 2026",
      status: "Asistencia",
      detail: "Asistencia confirmada durante el bloque tecnico.",
    ),
    TutorAttendanceRecord(
      dateLabel: "18 Mar 2026",
      status: "Retardo",
      detail: "Ingreso con retraso menor a 10 minutos.",
    ),
    TutorAttendanceRecord(
      dateLabel: "17 Mar 2026",
      status: "Falta",
      detail: "No asistio a clase y se requiere justificar la ausencia.",
    ),
    TutorAttendanceRecord(
      dateLabel: "14 Mar 2026",
      status: "Asistencia",
      detail: "Presente en todas las clases del dia.",
    ),
    TutorAttendanceRecord(
      dateLabel: "13 Mar 2026",
      status: "Asistencia",
      detail: "Sin observaciones.",
    ),
  ];

  const justifications = [
    TutorJustificationRecord(
      dateLabel: "17 Mar 2026",
      subjectName: "Fisica industrial",
      status: "Pendiente",
      reason: "Consulta medica",
      detail: "Hace falta adjuntar la constancia o ampliar el motivo.",
    ),
    TutorJustificationRecord(
      dateLabel: "27 Feb 2026",
      subjectName: "Matematicas aplicadas",
      status: "Aprobada",
      reason: "Cita familiar programada",
      detail: "Justificacion aceptada por coordinacion academica.",
    ),
    TutorJustificationRecord(
      dateLabel: "10 Feb 2026",
      subjectName: "Ingles tecnico",
      status: "En revision",
      reason: "Malestar general",
      detail: "Se envio comentario y se esta validando el soporte.",
    ),
  ];

  return TutorStudentSnapshot(
    tutorName: tutorName,
    studentName: "Diego Alejandro Marin",
    groupName: "TI-51",
    schoolPeriod: "Marzo 2026",
    totalAssistances: 45,
    totalAbsences: 3,
    grades: grades,
    comments: comments,
    reports: reports,
    activities: activities,
    attendanceHistory: attendanceHistory,
    justifications: justifications,
  );
}
