import 'package:flutter/material.dart';
import 'materia_models.dart';

class DetallesMateriaScreen extends StatelessWidget {
  final Materia materia;

  const DetallesMateriaScreen({super.key, required this.materia});

  @override
  Widget build(BuildContext context) {
    final colorPrincipal = materia.calificacionFinal >= 7.0
        ? Colors.teal
        : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(materia.nombre),
        backgroundColor: colorPrincipal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotaFinalCard(materia.calificacionFinal, colorPrincipal),
            const SizedBox(height: 20),
            _buildHeaderDetail('Semestre', materia.semestre, Colors.blueGrey),
            _buildHeaderDetail('Profesor', materia.profesor, Colors.blueGrey),
            _buildHeaderDetail('Estatus', materia.estatus, colorPrincipal),
            const SizedBox(height: 28),
            const Text(
              'Actividades y comentarios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (materia.evaluaciones.isEmpty)
              const Text(
                'Todavía no hay actividades registradas para esta materia.',
              )
            else
              ...materia.evaluaciones.map(_buildEvaluacionCard),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderDetail(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: color,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaFinalCard(double nota, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Nota Final: ${nota.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluacionCard(Evaluacion evaluacion) {
    final gradeColor = (evaluacion.calificacion ?? 0) >= 7
        ? Colors.green.shade700
        : Colors.orange.shade800;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    evaluacion.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  evaluacion.calificacion?.toStringAsFixed(1) ?? 'Sin nota',
                  style: TextStyle(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (evaluacion.comentario.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(evaluacion.comentario),
            ],
          ],
        ),
      ),
    );
  }
}
