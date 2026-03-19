import 'dart:math';

// -----------------------------------------------------------------
// 1. MODELOS DE DATOS
// -----------------------------------------------------------------

class Evaluacion {
  final String nombre;
  final double peso;
  final double? calificacion;
  final String comentario;
  final String fecha;
  final String tipo;

  Evaluacion({
    required this.nombre,
    required this.peso,
    required this.calificacion,
    this.comentario = '',
    this.fecha = '',
    this.tipo = 'actividad',
  });

  double get contribucion => ((calificacion ?? 0) * peso) / 100.0;

  factory Evaluacion.fromJson(Map<String, dynamic> json) {
    return Evaluacion(
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      peso: _parseToDouble(json['peso']),
      calificacion: _parseToNullableDouble(json['calificacion']),
      comentario: json['comentario']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'actividad',
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'peso': peso,
    'calificacion': calificacion,
    'comentario': comentario,
    'fecha': fecha,
    'tipo': tipo,
  };

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _parseToNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

// -----------------------------------------------------------------
// Modelo de la Materia
// -----------------------------------------------------------------

class Materia {
  final String nombre;
  final String profesor;
  final String semestre;
  final List<Evaluacion> evaluaciones;
  final double? calificacionFinalOverride;

  Materia({
    required this.nombre,
    required this.profesor,
    required this.semestre,
    required this.evaluaciones,
    this.calificacionFinalOverride,
  });

  double get calificacionFinal {
    if (calificacionFinalOverride != null) return calificacionFinalOverride!;
    if (evaluaciones.isEmpty) return 0.0;

    final total = evaluaciones.fold(0.0, (sum, e) => sum + e.contribucion);
    return min(total, 10.0);
  }

  String get estatus {
    if (calificacionFinalOverride == null &&
        evaluaciones.every((e) => e.calificacion == null)) {
      return 'En Curso';
    }
    if (calificacionFinal > 0 && calificacionFinal < 7.0) return 'Reprobada';
    if (calificacionFinal >= 7.0) return 'Aprobada';
    return 'En Curso';
  }

  factory Materia.fromBackendJson(Map<String, dynamic> json) {
    return Materia(
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      profesor: json['profesor']?.toString() ?? 'Sin profesor',
      semestre: json['semestre']?.toString() ?? 'Sin semestre',
      calificacionFinalOverride: Evaluacion._parseToNullableDouble(
        json['calificacion_final'],
      ),
      evaluaciones: (json['evaluaciones'] as List<dynamic>? ?? [])
          .map((e) => Evaluacion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia.fromBackendJson(json);
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'profesor': profesor,
    'semestre': semestre,
    'calificacion_final': calificacionFinalOverride,
    'evaluaciones': evaluaciones.map((e) => e.toJson()).toList(),
  };
}
