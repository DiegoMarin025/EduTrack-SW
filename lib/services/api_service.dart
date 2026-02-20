import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform; // Necesario para detectar si es Android/iOS
import 'package:flutter/foundation.dart'
    show kIsWeb; // Necesario para detectar Web
import '/pantallas/materia_models.dart'; 

// SERVICIO API
class ApiService {
  // CONFIGURACIÓN DE IP AUTOMÁTICA
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Web
    } else if (Platform.isAndroid) {
      return 'http://192.168.0.13:3000'; // Emulador Android
    } else {
      return 'http://localhost:3000'; // iOS / Desktop
    }
  }

  // 1. OBTENER GRUPOS (FILTRADO POR PROFESOR)
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
      // Retornamos el ID del nuevo usuario
      return body['id'];
    } else {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Error al registrar usuario');
    }
  }

  // ---------------------------------------------------------
  // 7. LOGIN
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> loginUser(
    String correo,
    String contrasena,
    // String tipoUsuario,  <--- ELIMINADO: Ya no se pide este parámetro
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'correo': correo,
        'contrasena': contrasena,
        // 'tipo_usuario': tipoUsuario, <--- ELIMINADO: Ya no se envía al servidor
      }),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['usuario'];
    } else {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Error al iniciar sesión');
    }
  }

  // ---------------------------------------------------------
  // 8. BUSCAR ALUMNOS
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // 9. AGREGAR ALUMNO A GRUPO
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // 10. OBTENER CATÁLOGO DE GRUPOS FÍSICOS
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // 11. CREAR CLASE (MATERIA) - VINCULA AL PROFESOR
  // ---------------------------------------------------------
  static Future<void> crearClase(
    int grupoId,
    String nombreMateria, {
    int? profesorId, // <--- Parámetro opcional para asignar al profesor
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clases/crear'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'grupo_id': grupoId,
        'nombre_materia': nombreMateria,
        'profesor_id': profesorId, // Enviamos el ID si existe
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error creando la clase');
    }
  }

  // ---------------------------------------------------------
  // 12. ELIMINAR ALUMNO DEL GRUPO
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // 13. VERIFICAR GRUPO DEL ALUMNO
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // 14. OBTENER STATS DEL PROFESOR
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // 15. DASHBOARD DEL ALUMNO
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // 16. ENVIAR REPORTE DE SOPORTE
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // 17. OBTENER HISTORIAL ACADÉMICO REAL
  // ---------------------------------------------------------
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
            .map((m) => Materia.fromJson(m)) // <-- ASÍ SE USA TU MODELO
            .toList();

        return MapEntry(semestre, listaMaterias);
      });
    } else {
      throw Exception('Error al obtener historial académico');
    }
  }
} // FIN DE ApiService

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
  final int id;
  final int grupoIdReal;
  final String nombre;
  final String materia;
  // Podemos agregar profesorId si lo necesitas en el frontend
  // final int profesorId;

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

// ---------------------------------------------------------
// MODELOS DEL DASHBOARD
// ---------------------------------------------------------
class Subject {
  final String materia;
  final double? calificacion;
  final String estado;

  Subject({required this.materia, this.calificacion, required this.estado});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      materia: json['materia'] as String,
      calificacion: json['calificacion'] != null
          ? (json['calificacion'] as num).toDouble()
          : null,
      estado: json['estado'] as String,
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
      average: (json['average'] as num).toDouble(),
      student: StudentData.fromJson(json['student'] as Map<String, dynamic>),
      subjects: subjectsList,
    );
  }
}
