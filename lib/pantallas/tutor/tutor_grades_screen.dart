import 'package:flutter/material.dart';

class TutorGradesScreen extends StatelessWidget {
  const TutorGradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo (Luego vendrán de la BD)
    final List<Map<String, dynamic>> materias = [
      {
        "nombre": "Matemáticas Aplicadas",
        "promedio": 9.5,
        "parciales": [9.0, 10.0, 9.5],
        "color": Colors.blue
      },
      {
        "nombre": "Física Industrial",
        "promedio": 8.2,
        "parciales": [7.5, 8.0, 9.1],
        "color": Colors.orange
      },
      {
        "nombre": "Programación Móvil",
        "promedio": 10.0,
        "parciales": [10.0, 10.0, 10.0],
        "color": Colors.green
      },
      {
        "nombre": "Inglés Técnico",
        "promedio": 7.8,
        "parciales": [7.0, 7.5, 9.0],
        "color": Colors.purple
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Calificaciones Detalladas', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A337E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- 1. RESUMEN DE PROMEDIO GENERAL (Punto 3.3.1) ---
          _buildGlobalAverageHeader(9.2),

          // --- 2. LISTA DE MATERIAS (Punto 3.3.2 y 3.3.3) ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: materias.length,
              itemBuilder: (context, index) {
                return _buildSubjectCard(materias[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Header con el promedio general
  Widget _buildGlobalAverageHeader(double promedio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A337E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Text("Promedio General", 
            style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Text("$promedio", 
            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // Una pequeña barra de progreso visual
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: promedio / 10,
              backgroundColor: Colors.white24,
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(10),
            ),
          )
        ],
      ),
    );
  }

  // Tarjeta por materia con desglose
  Widget _buildSubjectCard(Map<String, dynamic> materia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        shape: const Border(), // Quita la línea extra del ExpansionTile
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: materia['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.book, color: materia['color']),
        ),
        title: Text(materia['nombre'], 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A337E))),
        subtitle: Text("Promedio: ${materia['promedio']}"),
        trailing: const Icon(Icons.expand_more),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPartialGrade("1er Parcial", materia['parciales'][0]),
                    _buildPartialGrade("2do Parcial", materia['parciales'][1]),
                    _buildPartialGrade("3er Parcial", materia['parciales'][2]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para cada circulito de parcial
  Widget _buildPartialGrade(String label, double nota) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: nota >= 7 ? Colors.blue.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text("$nota", 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: nota >= 7 ? Colors.blue.shade900 : Colors.red.shade900
            )),
        ),
      ],
    );
  }
}