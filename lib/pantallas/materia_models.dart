import 'dart:math';

// -----------------------------------------------------------------
// 1. MODELOS DE DATOS
// -----------------------------------------------------------------

// Modelo de la Evaluación (la nota que sube el maestro)
class Evaluacion {
  final String nombre; // Ej: "Examen Parcial 1", "Tarea Unidad 2"
  final double peso; // Peso en porcentaje (ej: 30.0 para 30%)
  final double calificacion; // Nota real (0.0 - 10.0)

  Evaluacion({
    required this.nombre,
    required this.peso,
    required this.calificacion,
  });

  // Cálculo: Contribución al total
  double get contribucion => (calificacion * peso) / 100.0;

  // Factory desde JSON (¡BLINDADO CONTRA ERRORES DE TIPO!)
  factory Evaluacion.fromJson(Map<String, dynamic> json) {
    return Evaluacion(
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      // Usamos _parseToDouble para evitar el error "String is not subtype of num"
      peso: _parseToDouble(json['peso']),
      calificacion: _parseToDouble(json['calificacion']),
    );
  }

  Map<String, dynamic> toJson() => {
    "nombre": nombre,
    "peso": peso,
    "calificacion": calificacion,
  };

  // --- FUNCIÓN DE SEGURIDAD ---
  // Convierte cualquier cosa (String, Int, Double, Null) a un double seguro.
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      // Intenta convertir el texto "10.00" a número 10.0
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
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

  Materia({
    required this.nombre,
    required this.profesor,
    required this.semestre,
    required this.evaluaciones,
  });

  // Calcular calificación final
  double get calificacionFinal {
    if (evaluaciones.isEmpty) return 0.0;

    double total = evaluaciones.fold(0.0, (sum, e) => sum + e.contribucion);

    return min(total, 10.0); // nunca excede 10
  }

  // Estatus
  String get estatus {
    if (evaluaciones.isEmpty) return 'En Curso';
    // Si tiene nota pero es baja
    if (calificacionFinal > 0 && calificacionFinal < 7.0) return 'Reprobada';
    // Si ya pasó (puedes ajustar lógica si requieres que todas las evals estén listas)
    if (calificacionFinal >= 7.0) return 'Aprobada';

    return 'En Curso';
  }

  // ---------------------------------------------------------------
  // FACTORY: Desde backend JSON real
  // ---------------------------------------------------------------
  factory Materia.fromBackendJson(Map<String, dynamic> json) {
    return Materia(
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      profesor: json['profesor']?.toString() ?? 'Sin profesor',
      semestre: json['semestre']?.toString() ?? 'Sin semestre',
      evaluaciones: (json['evaluaciones'] as List<dynamic>? ?? [])
          .map((e) => Evaluacion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ---------------------------------------------------------------
  // FACTORY: Desde JSON local o frontend (Compatibilidad)
  // ---------------------------------------------------------------
  factory Materia.fromJson(Map<String, dynamic> json) {
    // Reutilizamos la lógica para mantener consistencia
    return Materia.fromBackendJson(json);
  }

  // ---------------------------------------------------------------
  // Convertir a JSON
  // ---------------------------------------------------------------
  Map<String, dynamic> toJson() => {
    "nombre": nombre,
    "profesor": profesor,
    "semestre": semestre,
    "evaluaciones": evaluaciones.map((e) => e.toJson()).toList(),
  };
}
