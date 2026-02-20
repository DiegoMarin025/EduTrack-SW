import 'package:flutter/material.dart';
import 'materia_models.dart';

class DetallesMateriaScreen extends StatelessWidget {
  final Materia materia; // Recibimos el objeto Materia completo

  const DetallesMateriaScreen({super.key, required this.materia});

  @override
  Widget build(BuildContext context) {
    // Definimos el color según la nota final de la materia
    Color colorPrincipal = materia.calificacionFinal >= 7.0
        ? Colors.teal
        : Colors.red;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Resumen y Nota Final ---
              _buildNotaFinalCard(materia.calificacionFinal, colorPrincipal),
              const SizedBox(height: 20),

              _buildHeaderDetail(
                'Semestre:',
                materia.semestre,
                Colors.blueGrey,
              ),
              _buildHeaderDetail(
                'Profesor:',
                materia.profesor,
                Colors.blueGrey,
              ),
              _buildHeaderDetail(
                'Estatus Final:',
                materia.estatus,
                colorPrincipal,
              ),

              const SizedBox(height: 30),

              // --- Desglose de Evaluaciones ---
              const Text(
                'Desglose de Evaluaciones:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 10),

              // Lista de Evaluaciones
              ...materia.evaluaciones.map((evaluacion) {
                return _buildEvaluacionRow(evaluacion);
              }).toList(),

              const SizedBox(height: 20),
              _buildPonderacionTotal(materia.evaluaciones),
            ],
          ),
        ),
      ),

      // 🔙 BOTÓN PARA VOLVER A LA PANTALLA ANTERIOR
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // --- WIDGETS AUXILIARES PARA DETALLES ---

  Widget _buildHeaderDetail(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNotaFinalCard(double nota, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
        ),
        child: Text(
          'Nota Final: ${nota.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluacionRow(Evaluacion evaluacion) {
    Color colorContribucion = evaluacion.contribucion >= 4.0
        ? Colors.green.shade800
        : Colors.red.shade800;

    return ListTile(
      title: Text(evaluacion.nombre),
      subtitle: Text('Peso: ${evaluacion.peso.toStringAsFixed(0)}%'),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            evaluacion.calificacion.toStringAsFixed(1),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Contribución: ${evaluacion.contribucion.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: colorContribucion),
          ),
        ],
      ),
    );
  }

  Widget _buildPonderacionTotal(List<Evaluacion> evaluaciones) {
    double totalPeso = evaluaciones.fold(0.0, (sum, item) => sum + item.peso);
    bool is100 = totalPeso.toStringAsFixed(0) == '100';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: is100 ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: is100 ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Ponderación Total Declarada:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${totalPeso.toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: is100 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // 🔙 BOTÓN PARA VOLVER A LA PANTALLA ANTERIOR
  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      child: TextButton.icon(
        icon: const Icon(Icons.arrow_back, color: Colors.teal),
        label: const Text("Volver", style: TextStyle(color: Colors.teal)),
        onPressed: () {
          Navigator.pop(context); // ⬅ Regresa a StudentDashboardScreen
        },
      ),
    );
  }
}
