import 'package:flutter/material.dart';
import 'dart:math';

// -----------------------------------------------------------------
// 1. MODELOS DE DATOS
// -----------------------------------------------------------------

class Estudiante {
  final String id;
  final String nombreCompleto;

  Estudiante({required this.id, required this.nombreCompleto});
}

// Modelo de la Evaluación (la nota que sube el maestro)
class EvaluacionInput {
  String nombre = '';
  double ponderacion = 0.0; // Peso en porcentaje (ej. 30.0 para 30%)
  double calificacion = 0.0; // Nota real (0.0 - 10.0)
}

// Datos de estudiantes y materias simulados (simulando la base de datos)
final List<Estudiante> _mockEstudiantes = [
  Estudiante(id: 'S001', nombreCompleto: 'Ana Belén Martínez'),
  Estudiante(id: 'S002', nombreCompleto: 'Carlos Daniel Gómez'),
  Estudiante(id: 'S003', nombreCompleto: 'Diana Laura Ramos'),
  Estudiante(id: 'S004', nombreCompleto: 'Emilio Javier Flores'),
];

final List<String> _mockMaterias = [
  'Programación Móvil (Flutter)',
  'Cálculo Multivariable',
  'Diseño de Interacción UX/UI',
];

class TeacherGradeInputScreen extends StatefulWidget {
  const TeacherGradeInputScreen({super.key});

  @override
  State<TeacherGradeInputScreen> createState() =>
      _TeacherGradeInputScreenState();
}

class _TeacherGradeInputScreenState extends State<TeacherGradeInputScreen> {
  // -----------------------------------------------------------------
  // 2. ESTADO DE LA PANTALLA
  // -----------------------------------------------------------------
  Estudiante? _estudianteSeleccionado;
  String? _materiaSeleccionada;
  List<EvaluacionInput> _evaluaciones = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Inicia con una fila de evaluación vacía
    _agregarEvaluacion();
  }

  // -----------------------------------------------------------------
  // 3. FUNCIONES DE LÓGICA
  // -----------------------------------------------------------------
  // Agrega una nueva fila de evaluación
  void _agregarEvaluacion() {
    setState(() {
      _evaluaciones.add(EvaluacionInput());
    });
  }

  // Elimina una fila de evaluación
  void _eliminarEvaluacion(int index) {
    setState(() {
      _evaluaciones.removeAt(index);
    });
  }

  // Muestra un diálogo para que el profesor seleccione un estudiante
  void _seleccionarEstudiante(BuildContext context) {
    showDialog<Estudiante>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Seleccionar Estudiante'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _mockEstudiantes.map((estudiante) {
                return ListTile(
                  title: Text(estudiante.nombreCompleto),
                  onTap: () {
                    Navigator.pop(dialogContext, estudiante);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    ).then((estudiante) {
      if (estudiante != null) {
        setState(() {
          _estudianteSeleccionado = estudiante;
        });
      }
    });
  }

  // Calcula y valida que la ponderación total sea 100%
  String? _validarPonderacion() {
    double sumaPonderaciones = 0;
    for (var eval in _evaluaciones) {
      sumaPonderaciones += eval.ponderacion;
    }

    if (sumaPonderaciones.toStringAsFixed(0) != '100' &&
        _evaluaciones.isNotEmpty) {
      return 'La suma de las ponderaciones debe ser 100%. Suma actual: ${sumaPonderaciones.toStringAsFixed(1)}%';
    }
    return null;
  }

  // Simula el guardado de datos en la base de datos
  void _guardarCalificaciones() {
    if (_formKey.currentState!.validate()) {
      // 1. Validar Ponderación al final
      final ponderacionError = _validarPonderacion();
      if (ponderacionError != null) {
        // Muestra un error si la suma no es 100%
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $ponderacionError'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _formKey.currentState!.save();

      // 2. Validaciones finales
      if (_estudianteSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, seleccione un estudiante.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_materiaSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, seleccione una materia.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 3. Simulación de envío de datos
      double calificacionFinalCalculada = 0.0;
      for (var eval in _evaluaciones) {
        calificacionFinalCalculada +=
            (eval.ponderacion / 100.0) * eval.calificacion;
      }

      // 4. Muestra un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guardado para ${_estudianteSeleccionado!.nombreCompleto} en $_materiaSeleccionada.\nNota Final Calculada: ${calificacionFinalCalculada.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Aquí iría la lógica real para subir los datos a Firestore/API.
      // print('Datos a guardar:');
      // print('Estudiante ID: ${_estudianteSeleccionado!.id}');
      // print('Materia: $_materiaSeleccionada');
      // _evaluaciones.forEach((e) => print(' -> ${e.nombre}: ${e.calificacion} (${e.ponderacion}%)'));
    }
  }

  // -----------------------------------------------------------------
  // 4. WIDGETS DE CONSTRUCCIÓN (UI)
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Panel Superior de Selección
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEstudianteSelector(),
                  const SizedBox(height: 12),
                  _buildMateriaSelector(),
                  const SizedBox(height: 16),
                  const Text(
                    'Evaluaciones del Periodo:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),

            // Formulario Dinámico de Evaluaciones
            Expanded(
              child: ListView.builder(
                itemCount: _evaluaciones.length,
                itemBuilder: (context, index) {
                  return _buildEvaluacionRow(index);
                },
              ),
            ),

            // Pie de Página: Ponderación Total y Botón Guardar
            _buildFooter(),
          ],
        ),
      ),
      // Botón flotante para agregar más evaluaciones
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarEvaluacion,
        tooltip: 'Agregar Evaluación',
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Construye la caja para seleccionar al estudiante
  Widget _buildEstudianteSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _estudianteSeleccionado == null
                  ? 'Estudiante: SIN SELECCIONAR'
                  : 'Estudiante: ${_estudianteSeleccionado!.nombreCompleto}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _estudianteSeleccionado == null
                    ? Colors.red.shade700
                    : Colors.indigo.shade900,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _seleccionarEstudiante(context),
            icon: const Icon(Icons.person_search),
            label: const Text('Elegir Estudiante'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Construye el selector de materia (Dropdown)
  Widget _buildMateriaSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Materia a Calificar',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        fillColor: Colors.grey.shade50,
        filled: true,
      ),
      value: _materiaSeleccionada,
      hint: const Text('Seleccione una materia'),
      items: _mockMaterias.map((String materia) {
        return DropdownMenuItem<String>(value: materia, child: Text(materia));
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _materiaSeleccionada = newValue;
        });
      },
      validator: (value) => value == null ? 'Campo requerido' : null,
    );
  }

  // Construye la fila individual para ingresar una calificación
  Widget _buildEvaluacionRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nombre de la Evaluación
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: _evaluaciones[index].nombre,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Examen Parcial',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onSaved: (value) => _evaluaciones[index].nombre = value ?? '',
              validator: (value) => value!.isEmpty ? 'Requerido' : null,
            ),
          ),
          const SizedBox(width: 8),

          // 2. Ponderación (%)
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: _evaluaciones[index].ponderacion.toStringAsFixed(1),
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Peso (%)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onSaved: (value) => _evaluaciones[index].ponderacion =
                  double.tryParse(value!) ?? 0.0,
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Número';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),

          // 3. Calificación (Nota)
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: _evaluaciones[index].calificacion == 0.0
                  ? ''
                  : _evaluaciones[index].calificacion.toStringAsFixed(1),
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Nota (0-10)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onSaved: (value) => _evaluaciones[index].calificacion =
                  double.tryParse(value!) ?? 0.0,
              validator: (value) {
                final nota = double.tryParse(value ?? '');
                if (nota == null || nota < 0 || nota > 10) {
                  return '0-10';
                }
                return null;
              },
            ),
          ),
          // 4. Botón de Eliminar Fila
          Visibility(
            visible: _evaluaciones.length > 1,
            child: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _eliminarEvaluacion(index),
              tooltip: 'Eliminar esta evaluación',
            ),
          ),
        ],
      ),
    );
  }

  // Construye el pie de página con el total de ponderación y el botón de guardar
  Widget _buildFooter() {
    double sumaPonderaciones = _evaluaciones.fold(
      0.0,
      (sum, item) => sum + item.ponderacion,
    );
    String? ponderacionError = _validarPonderacion();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Ponderado:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ponderacionError == null ? Colors.black : Colors.red,
                ),
              ),
              Text(
                '${sumaPonderaciones.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ponderacionError == null
                      ? Colors.indigo
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
          if (ponderacionError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                ponderacionError,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _guardarCalificaciones,
            icon: const Icon(Icons.save),
            label: const Text('Guardar Calificaciones'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
