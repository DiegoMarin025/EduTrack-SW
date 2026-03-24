import 'api_service.dart';

enum EstadoAsistencia { presente, ausente, retardo }

class AsistenciaAlumno {
  final int alumnoId;
  final String nombreAlumno;
  final String correoAlumno;
  final EstadoAsistencia estado;
  final String nota;

  AsistenciaAlumno({
    required this.alumnoId,
    required this.nombreAlumno,
    required this.correoAlumno,
    required this.estado,
    required this.nota,
  });
}

class AsistenciaRegistro {
  final int id;
  final int grupoId;
  final String grupoNombre;
  final String materia;
  final DateTime fecha;
  final List<AsistenciaAlumno> detalles;

  AsistenciaRegistro({
    required this.id,
    required this.grupoId,
    required this.grupoNombre,
    required this.materia,
    required this.fecha,
    required this.detalles,
  });

  int get presentes =>
      detalles.where((e) => e.estado == EstadoAsistencia.presente).length;

  int get ausentes =>
      detalles.where((e) => e.estado == EstadoAsistencia.ausente).length;

  int get retardos =>
      detalles.where((e) => e.estado == EstadoAsistencia.retardo).length;
}

class AsistenciaAlumnoHistorialItem {
  final AsistenciaRegistro registro;
  final AsistenciaAlumno detalle;

  const AsistenciaAlumnoHistorialItem({
    required this.registro,
    required this.detalle,
  });
}

class AsistenciaService {
  static Future<void> guardarAsistencia({
    required Grupo grupo,
    required DateTime fecha,
    required List<Alumno> alumnos,
    required Map<int, EstadoAsistencia> estados,
    required Map<int, String> notas,
  }) async {
    final detalles = alumnos.map((alumno) {
      return AttendanceApiDetailDraft(
        alumnoId: alumno.id,
        estado: _estadoToApi(estados[alumno.id] ?? EstadoAsistencia.presente),
        nota: notas[alumno.id] ?? '',
      );
    }).toList();

    await ApiService.guardarAsistenciaClase(
      claseId: grupo.id,
      fecha: fecha,
      detalles: detalles,
    );
  }

  static Future<List<AsistenciaRegistro>> obtenerHistorialPorGrupo(
    int grupoId,
  ) async {
    final registros = await ApiService.getAsistenciasPorClase(grupoId);
    return registros.map(_mapRecord).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  static Future<AsistenciaRegistro?> obtenerPorId(int id) async {
    final record = await ApiService.getAsistenciaPorId(id);
    return record == null ? null : _mapRecord(record);
  }

  static Future<List<AsistenciaAlumnoHistorialItem>> obtenerHistorialPorAlumno(
    int alumnoId,
  ) async {
    final items = await ApiService.getAsistenciasPorAlumno(alumnoId);
    final historial = items.map(_mapStudentItem).toList();
    historial.sort((a, b) => b.registro.fecha.compareTo(a.registro.fecha));
    return historial;
  }

  static AsistenciaRegistro _mapRecord(AttendanceApiRecord record) {
    return AsistenciaRegistro(
      id: record.id,
      grupoId: record.grupoId,
      grupoNombre: record.grupoNombre,
      materia: record.materia,
      fecha: _parseDate(record.fecha),
      detalles: record.detalles.map(_mapDetail).toList(),
    );
  }

  static AsistenciaAlumnoHistorialItem _mapStudentItem(
    AttendanceApiStudentItem item,
  ) {
    final detalle = AsistenciaAlumno(
      alumnoId: item.alumnoId,
      nombreAlumno: item.alumnoNombre,
      correoAlumno: item.alumnoCorreo,
      estado: _estadoFromApi(item.estado),
      nota: item.nota,
    );

    final registro = AsistenciaRegistro(
      id: item.registroId,
      grupoId: item.claseId,
      grupoNombre: item.grupoNombre,
      materia: item.materia,
      fecha: _parseDate(item.fecha),
      detalles: [detalle],
    );

    return AsistenciaAlumnoHistorialItem(
      registro: registro,
      detalle: detalle,
    );
  }

  static AsistenciaAlumno _mapDetail(AttendanceApiDetail detail) {
    return AsistenciaAlumno(
      alumnoId: detail.alumnoId,
      nombreAlumno: detail.nombre,
      correoAlumno: detail.correo,
      estado: _estadoFromApi(detail.estado),
      nota: detail.nota,
    );
  }

  static EstadoAsistencia _estadoFromApi(String value) {
    switch (value.trim().toLowerCase()) {
      case 'presente':
        return EstadoAsistencia.presente;
      case 'retardo':
        return EstadoAsistencia.retardo;
      default:
        return EstadoAsistencia.ausente;
    }
  }

  static String _estadoToApi(EstadoAsistencia value) {
    switch (value) {
      case EstadoAsistencia.presente:
        return 'presente';
      case EstadoAsistencia.retardo:
        return 'retardo';
      case EstadoAsistencia.ausente:
        return 'ausente';
    }
  }

  static DateTime _parseDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return parsed;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
