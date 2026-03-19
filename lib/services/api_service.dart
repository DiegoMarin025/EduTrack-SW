import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform; // Android/iOS
import 'package:flutter/foundation.dart' show kIsWeb; // Web
import '/pantallas/materia_models.dart';

// SERVICIO API
class ApiService {
  // CONFIGURACIÓN DE IP AUTOMÁTICA
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Web
    } else if (Platform.isAndroid) {
      return 'http://192.168.0.13:3000'; // Android (tu IP)
    } else {
      return 'http://localhost:3000'; // iOS / Desktop
    }
  }

  static Future<List<GrupoBundle>> getMisGruposAgrupados(int profesorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mis_grupos?profesor_id=$profesorId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((e) => GrupoBundle.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar mis grupos: ${response.body}');
    }
  }

  // 1. OBTENER GRUPOS (FILTRADO POR PROFESOR) -> tu endpoint viejo /grupos
  static Future<List<Grupo>> getGrupos({int? profesorId}) async {
    String url = '$baseUrl/grupos';
    if (profesorId != null) {
      url += '?profesor_id=$profesorId';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((jsonItem) => Grupo.fromJson(jsonItem as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar grupos');
    }
  }

  // 2. OBTENER ALUMNOS POR GRUPO
  // OJO: en tu backend, este endpoint espera "clase_id" = materias_grupos.id (mg.id)
  // y NO el id del grupo físico.
  static Future<List<Alumno>> getAlumnosPorGrupo(int grupoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grupos/$grupoId/alumnos'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => Alumno.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar alumnos');
    }
  }

  // 3. OBTENER CALIFICACIÓN
  // OJO: grupoId aquí en realidad es "mg.id" (materias_grupos.id)
  static Future<List<CalificacionesResumenAlumno>> getCalificacionesResumen(
    int grupoId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/grupos/$grupoId/calificaciones_resumen'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map(
            (item) => CalificacionesResumenAlumno.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } else {
      throw Exception('Error al cargar el libro de calificaciones');
    }
  }

  static Future<String?> getCalificacion(int alumnoId, int grupoId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/calificaciones?alumno_id=$alumnoId&grupo_id=$grupoId',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data[0]['calificacion'].toString();
      }
      return null;
    } else {
      throw Exception('Error al obtener calificación');
    }
  }

  // 4. GUARDAR CALIFICACIÓN
  // OJO: grupoId aquí en realidad es "mg.id"
  static Future<void> guardarCalificacion(
    int alumnoId,
    int grupoId,
    double calificacion,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calificaciones'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'alumno_id': alumnoId,
        'grupo_id': grupoId,
        'calificacion': calificacion,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al guardar: ${response.body}');
    }
  }

  // 5. OBTENER NOTIFICACIONES
  static Future<List<ActividadCalificacion>> getActividadesCalificacion(
    int alumnoId,
    int grupoId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/calificaciones_actividades?alumno_id=$alumnoId&grupo_id=$grupoId',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map(
            (item) =>
                ActividadCalificacion.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else {
      throw Exception('Error al cargar actividades');
    }
  }

  static Future<void> guardarActividadCalificacion({
    required int alumnoId,
    required int grupoId,
    required String titulo,
    double? calificacion,
    String? comentario,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calificaciones_actividades'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'alumno_id': alumnoId,
        'grupo_id': grupoId,
        'titulo': titulo,
        'calificacion': calificacion,
        'comentario': comentario,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Error al guardar actividad');
    }
  }

  static Future<List<Notificacion>> getNotificaciones(int usuarioId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notificaciones/$usuarioId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => Notificacion.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar notificaciones');
    }
  }

  // 6. REGISTRAR USUARIO (RETORNA ID)
  static Future<int> registerUser(
    String nombre,
    String correo,
    String contrasena,
    String tipoUsuario,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
        'tipo_usuario': tipoUsuario,
      }),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['id'];
    } else {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Error al registrar usuario');
    }
  }

  // 7. LOGIN
  static Future<Map<String, dynamic>> loginUser(
    String correo,
    String contrasena,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'correo': correo, 'contrasena': contrasena}),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['usuario'];
    } else {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Error al iniciar sesión');
    }
  }

  // 8. BUSCAR ALUMNOS
  static Future<List<Alumno>> buscarAlumnos(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/alumnos/buscar?q=$query'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => Alumno.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error buscando alumnos');
    }
  }

  // 8.1 CREAR ALUMNO (NUEVO) -> reutiliza /register
  static Future<Alumno> crearAlumno({
    required String nombre,
    required String correo,
  }) async {
    final nombreClean = nombre.trim();
    final correoClean = correo.trim();

    if (nombreClean.isEmpty) throw Exception('El nombre es obligatorio');
    if (correoClean.isEmpty) throw Exception('El correo es obligatorio');

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombreClean,
        'correo': correoClean,
        'contrasena': 'Temp12345*',
        'tipo_usuario': 'alumno',
      }),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final int id = body['id'] is int
          ? body['id']
          : int.parse(body['id'].toString());
      return Alumno(id: id, nombre: nombreClean, correo: correoClean);
    } else {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Error al crear alumno');
    }
  }

  // 9. AGREGAR ALUMNO A GRUPO
  // IMPORTANTE: aquí "grupoId" es el grupo físico (grupos.id)
  static Future<void> agregarAlumnoAGrupo(int alumnoId, int grupoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/grupos/agregar_alumno'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'alumno_id': alumnoId, 'grupo_id': grupoId}),
    );

    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Error al agregar alumno');
    }
  }

  // 10. OBTENER CATÁLOGO DE GRUPOS FÍSICOS
  static Future<List<GrupoFisico>> getGruposFisicos() async {
    final response = await http.get(Uri.parse('$baseUrl/grupos_disponibles'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => GrupoFisico.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error cargando catálogo de grupos');
    }
  }

  // 11. CREAR CLASE (MATERIA) - VINCULA AL PROFESOR
  static Future<void> crearClase(
    int grupoId,
    String nombreMateria, {
    int? profesorId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clases/crear'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'grupo_id': grupoId,
        'nombre_materia': nombreMateria,
        'profesor_id': profesorId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error creando la clase');
    }
  }

  // 12. ELIMINAR ALUMNO DEL GRUPO
  static Future<void> eliminarAlumnoDeGrupo(int alumnoId, int grupoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/grupos/eliminar_alumno'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'alumno_id': alumnoId, 'grupo_id': grupoId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar alumno');
    }
  }

  // 13. VERIFICAR GRUPO DEL ALUMNO
  static Future<Map<String, dynamic>> verificarGrupoAlumno(int alumnoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/alumnos/$alumnoId/grupo'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error verificando grupo');
    }
  }

  // 14. OBTENER STATS DEL PROFESOR
  static Future<Map<String, dynamic>> getProfesorStats(int profesorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profesor/$profesorId/stats'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener estadísticas del profesor');
    }
  }

  // 15. DASHBOARD DEL ALUMNO
  static Future<DashboardData> getStudentDashboard(int alumnoId) async {
    final url = Uri.parse('$baseUrl/dashboard/$alumnoId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return DashboardData.fromJson(jsonResponse);
    } else {
      throw Exception(
        'Error al cargar dashboard: Código ${response.statusCode}',
      );
    }
  }

  // 16. ENVIAR REPORTE DE SOPORTE
  static Future<void> enviarReporteSoporte(
    int usuarioId,
    String email,
    String mensaje,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reportes_soporte'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'usuario_id': usuarioId,
        'email': email,
        'mensaje': mensaje,
      }),
    );

    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Error al enviar reporte');
    }
  }

  // 17. OBTENER HISTORIAL ACADÉMICO REAL
  static Future<Map<String, List<Materia>>> getHistorialAcademico(
    int alumnoId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/historial_academico/$alumnoId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (!data.containsKey("semestres")) {
        throw Exception("Formato inesperado del servidor");
      }

      final semestres = data["semestres"] as Map<String, dynamic>;

      return semestres.map((semestre, materias) {
        final listaMaterias = (materias as List)
            .map((m) => Materia.fromJson(m))
            .toList();
        return MapEntry(semestre, listaMaterias);
      });
    } else {
      throw Exception('Error al obtener historial académico');
    }
  }
} // FIN DE ApiService

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

// ==========================================
// MODELOS (Incluidos aquí para facilitar la copia)
// ==========================================

class GrupoFisico {
  final int id;
  final String nombre;
  GrupoFisico({required this.id, required this.nombre});
  factory GrupoFisico.fromJson(Map<String, dynamic> json) {
    return GrupoFisico(id: json['id'], nombre: json['nombre']);
  }
}

class Grupo {
  final int id; // mg.id
  final int grupoIdReal; // grupos.id
  final String nombre; // grupos.nombre
  final String materia; // materias.nombre

  Grupo({
    required this.id,
    required this.grupoIdReal,
    required this.nombre,
    required this.materia,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) {
    return Grupo(
      id: json['id'],
      grupoIdReal: json['grupo_id'] ?? 0,
      nombre: json['nombre'] ?? '',
      materia: json['materia'] ?? '',
    );
  }
}

class Alumno {
  final int id;
  final String nombre;
  final String correo;

  Alumno({required this.id, required this.nombre, required this.correo});

  factory Alumno.fromJson(Map<String, dynamic> json) {
    return Alumno(
      id: json['id'],
      nombre: json['nombre'] ?? 'Sin nombre',
      correo: json['correo'] ?? (json['email'] ?? 'Sin correo'),
    );
  }
}

class CalificacionesResumenAlumno {
  final int id;
  final String nombre;
  final String correo;
  final double? calificacionFinal;
  final int totalActividades;
  final double? promedioActividades;
  final String ultimoComentario;

  const CalificacionesResumenAlumno({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.calificacionFinal,
    required this.totalActividades,
    required this.promedioActividades,
    required this.ultimoComentario,
  });

  factory CalificacionesResumenAlumno.fromJson(Map<String, dynamic> json) {
    return CalificacionesResumenAlumno(
      id: _asInt(json['id']),
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      correo: json['correo']?.toString() ?? 'Sin correo',
      calificacionFinal: _asNullableDouble(json['calificacion_final']),
      totalActividades: _asInt(json['total_actividades']),
      promedioActividades: _asNullableDouble(json['promedio_actividades']),
      ultimoComentario: json['ultimo_comentario']?.toString() ?? '',
    );
  }

  CalificacionesResumenAlumno copyWith({
    double? calificacionFinal,
    int? totalActividades,
    double? promedioActividades,
    String? ultimoComentario,
  }) {
    return CalificacionesResumenAlumno(
      id: id,
      nombre: nombre,
      correo: correo,
      calificacionFinal: calificacionFinal ?? this.calificacionFinal,
      totalActividades: totalActividades ?? this.totalActividades,
      promedioActividades: promedioActividades ?? this.promedioActividades,
      ultimoComentario: ultimoComentario ?? this.ultimoComentario,
    );
  }
}

class ActividadCalificacion {
  final int id;
  final String titulo;
  final double? calificacion;
  final String comentario;
  final String fecha;
  final String tipo;

  const ActividadCalificacion({
    required this.id,
    required this.titulo,
    required this.calificacion,
    required this.comentario,
    required this.fecha,
    required this.tipo,
  });

  factory ActividadCalificacion.fromJson(Map<String, dynamic> json) {
    return ActividadCalificacion(
      id: _asInt(json['id']),
      titulo: json['titulo']?.toString() ?? 'Actividad',
      calificacion: _asNullableDouble(json['calificacion']),
      comentario: json['comentario']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'actividad',
    );
  }
}

class Notificacion {
  final int id;
  final String titulo;
  final String mensaje;
  final bool leida;
  final String fecha;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    required this.fecha,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    bool isLeida = json['leida'] == 1 || json['leida'] == true;
    return Notificacion(
      id: json['id'],
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      leida: isLeida,
      fecha: json['fecha'] != null ? json['fecha'].toString() : '',
    );
  }
}

// =========================================================
// ✅ NUEVOS MODELOS PARA /mis_grupos (AGRUPADO)
// =========================================================
class GrupoBundle {
  final int grupoId; // grupos.id
  final String nombre; // grupos.nombre
  final int totalAlumnos;
  final List<MateriaItem> materias;

  GrupoBundle({
    required this.grupoId,
    required this.nombre,
    required this.totalAlumnos,
    required this.materias,
  });

  factory GrupoBundle.fromJson(Map<String, dynamic> json) {
    final mats = (json['materias'] as List? ?? [])
        .map((e) => MateriaItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return GrupoBundle(
      grupoId: json['grupo_id'],
      nombre: json['nombre'] ?? '',
      totalAlumnos: (json['total_alumnos'] ?? 0) is int
          ? (json['total_alumnos'] ?? 0)
          : int.tryParse(json['total_alumnos'].toString()) ?? 0,
      materias: mats,
    );
  }
}

class MateriaItem {
  final int claseId; // ✅ mg.id (materias_grupos.id)
  final int materiaId; // materias.id
  final String materia; // materias.nombre

  MateriaItem({
    required this.claseId,
    required this.materiaId,
    required this.materia,
  });

  factory MateriaItem.fromJson(Map<String, dynamic> json) {
    return MateriaItem(
      claseId: json['clase_id'],
      materiaId: json['materia_id'],
      materia: json['materia'] ?? '',
    );
  }
}

// ---------------------------------------------------------
// MODELOS DEL DASHBOARD
// ---------------------------------------------------------
class Subject {
  final int claseId;
  final String materia;
  final double? calificacion;
  final String estado;
  final int totalActividades;
  final List<ActividadCalificacion> actividades;

  Subject({
    required this.claseId,
    required this.materia,
    this.calificacion,
    required this.estado,
    required this.totalActividades,
    required this.actividades,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    final rawActivities = json['actividades'] as List? ?? const [];
    return Subject(
      claseId: _asInt(json['clase_id']),
      materia: json['materia'] as String,
      calificacion: _asNullableDouble(json['calificacion']),
      estado: json['estado'] as String,
      totalActividades: _asInt(json['total_actividades']),
      actividades: rawActivities
          .map(
            (item) =>
                ActividadCalificacion.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class StudentData {
  final String nombre;
  final String carrera;
  final String matricula;

  StudentData({
    required this.nombre,
    required this.carrera,
    required this.matricula,
  });

  factory StudentData.fromJson(Map<String, dynamic> json) {
    return StudentData(
      nombre: json['nombre'] as String,
      carrera: json['carrera'] as String,
      matricula: json['matricula'] as String,
    );
  }
}

class DashboardData {
  final double average;
  final StudentData student;
  final List<Subject> subjects;

  DashboardData({
    required this.average,
    required this.student,
    required this.subjects,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var list = json['subjects'] as List;
    List<Subject> subjectsList = list
        .map((i) => Subject.fromJson(i as Map<String, dynamic>))
        .toList();

    return DashboardData(
      average: _asNullableDouble(json['average']) ?? 0,
      student: StudentData.fromJson(json['student'] as Map<String, dynamic>),
      subjects: subjectsList,
    );
  }
}
