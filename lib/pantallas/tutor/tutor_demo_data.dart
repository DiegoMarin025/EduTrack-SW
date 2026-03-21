class TutorStudentSnapshot {
  // Snapshot comun para TODAS las pantallas de tutor.
  // La idea es que futuras integraciones llenen esta estructura desde backend/Firebase
  // y no desde widgets individuales.
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
    if (grades.isEmpty) {
      return const TutorSubjectGrade(
        subjectName: "Calificaciones pendientes",
        teacherName: "Sin docente asignado",
        teacherNote: "Aqui apareceran las calificaciones cuando exista informacion academica vinculada.",
        average: 0,
        partials: [0, 0, 0],
      );
    }

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
  // Dataset de respaldo solo para la experiencia tutor.
  // Mantenerlo mientras la migracion no cubra asistencia, actividades,
  // comentarios y justificaciones reales.
  return TutorStudentSnapshot(
    tutorName: tutorName,
    studentName: "Alumno pendiente de vincular",
    groupName: "Pendiente",
    schoolPeriod: "Sin informacion academica",
    totalAssistances: 0,
    totalAbsences: 0,
    grades: const [],
    comments: const [],
    reports: const [],
    activities: const [],
    attendanceHistory: const [],
    justifications: const [],
  );
}
