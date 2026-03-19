import '../services/api_service.dart';

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

class AsistenciaService {
  static final List<AsistenciaRegistro> _registros = [];
  static int _nextId = 1;

  static Future<void> guardarAsistencia({
    required Grupo grupo,
    required DateTime fecha,
    required List<Alumno> alumnos,
    required Map<int, EstadoAsistencia> estados,
    required Map<int, String> notas,
  }) async {
    final detalles = alumnos.map((a) {
      return AsistenciaAlumno(
        alumnoId: a.id,
        nombreAlumno: a.nombre,
        correoAlumno: a.correo,
        estado: estados[a.id] ?? EstadoAsistencia.presente,
        nota: notas[a.id] ?? '',
      );
    }).toList();

    final existenteIndex = _registros.indexWhere(
      (r) =>
          r.grupoId == grupo.id &&
          r.fecha.year == fecha.year &&
          r.fecha.month == fecha.month &&
          r.fecha.day == fecha.day,
    );

    final nuevoRegistro = AsistenciaRegistro(
      id: existenteIndex >= 0 ? _registros[existenteIndex].id : _nextId++,
      grupoId: grupo.id,
      grupoNombre: grupo.nombre,
      materia: grupo.materia,
      fecha: fecha,
      detalles: detalles,
    );

    if (existenteIndex >= 0) {
      _registros[existenteIndex] = nuevoRegistro;
    } else {
      _registros.insert(0, nuevoRegistro);
    }
  }

  static Future<List<AsistenciaRegistro>> obtenerHistorialPorGrupo(
    int grupoId,
  ) async {
    final lista = _registros.where((r) => r.grupoId == grupoId).toList();
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  static Future<AsistenciaRegistro?> obtenerPorId(int id) async {
    try {
      return _registros.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
