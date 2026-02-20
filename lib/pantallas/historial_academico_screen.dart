import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'materia_models.dart'; // Asegúrate de que este archivo existe en la misma carpeta o ajusta la ruta
// Si está en la misma carpeta: import 'materia_models.dart';
// Si está en lib: import '../materia_models.dart';

class HistorialAcademicoScreen extends StatefulWidget {
  final int alumnoId;
  final Function(int)
  onNavigate; // Callback para cambiar de pestaña en MainLayout

  const HistorialAcademicoScreen({
    super.key,
    required this.alumnoId,
    required this.onNavigate,
  });

  @override
  State<HistorialAcademicoScreen> createState() =>
      _HistorialAcademicoScreenState();
}

class _HistorialAcademicoScreenState extends State<HistorialAcademicoScreen> {
  Map<String, List<Materia>> historial = {};
  String? semestreSeleccionado;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  // ---------------------------------------------------------------------------
  // CARGAR HISTORIAL REAL DEL BACKEND
  // ---------------------------------------------------------------------------
  Future<void> _cargarHistorial() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await ApiService.getHistorialAcademico(widget.alumnoId);

      if (mounted) {
        setState(() {
          historial = data;
          // Seleccionamos el primer semestre disponible por defecto
          semestreSeleccionado = data.keys.isNotEmpty ? data.keys.first : null;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = "No se pudo conectar con el servidor.\n\nDetalles: $e";
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // COLOR SEGÚN CALIFICACIÓN
  // ---------------------------------------------------------------------------
  Color _getCalificacionColor(double nota, String estatus) {
    if (estatus == "En Curso") return Colors.blueGrey.shade400;
    if (nota >= 9.0) return Colors.green.shade700;
    if (nota >= 7.0) return Colors.indigo.shade700;
    return Colors.red.shade700;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 50,
                  color: Colors.grey,
                ),
                const SizedBox(height: 15),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _cargarHistorial,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reintentar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (semestreSeleccionado == null || historial.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_edu, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text("No hay materias registradas en el historial."),
            ],
          ),
        ),
      );
    }

    final materias = historial[semestreSeleccionado]!;

    // Calcular promedio del semestre seleccionado
    double promedio = materias.isNotEmpty
        ? materias.fold(0.0, (sum, m) => sum + m.calificacionFinal) /
              materias.length
        : 0.0;

    return Scaffold(
      body: Column(
        children: [
          // Selector de Semestres (Chips)
          _buildSemestreSelector(),

          // Resumen de Promedio
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[50],
            child: Column(
              children: [
                Text(
                  "Promedio del Semestre",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  promedio.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getCalificacionColor(promedio, "Finalizado"),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de Materias
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: materias.length,
              itemBuilder: (context, i) {
                return _buildMateriaCard(materias[i]);
              },
            ),
          ),
        ],
      ),

      // Botón Flotante para Soporte
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pestaña de Ayuda (Índice 3 en MainLayout)
          widget.onNavigate(3);
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.support_agent, color: Colors.white),
        tooltip: 'Contactar Soporte',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SELECTOR DE SEMESTRE
  // ---------------------------------------------------------------------------
  Widget _buildSemestreSelector() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: historial.keys.map((semestre) {
          bool selected = semestre == semestreSeleccionado;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: ChoiceChip(
              label: Text(semestre),
              selected: selected,
              selectedColor: Colors.deepPurple.shade100,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.deepPurple : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? Colors.deepPurple : Colors.grey.shade300,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  semestreSeleccionado = semestre;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD DE MATERIA
  // ---------------------------------------------------------------------------
  Widget _buildMateriaCard(Materia materia) {
    double nota = materia.calificacionFinal;
    String estatus = materia.estatus ?? "Finalizado"; // Asegurar valor
    Color color = _getCalificacionColor(nota, estatus);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.book, color: color),
        ),
        title: Text(
          materia.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            "Prof: ${materia.profesor}",
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              estatus == "En Curso" ? "Cursando" : nota.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (estatus != "En Curso")
              Text(
                nota >= 7.0 ? "Aprobada" : "Reprobada",
                style: TextStyle(
                  fontSize: 10,
                  color: nota >= 7.0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        onTap: () {
          // Aquí podrías navegar a detalles si tienes esa pantalla
          /*
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetallesMateriaScreen(materia: materia),
            ),
          );
          */
        },
      ),
    );
  }
}
