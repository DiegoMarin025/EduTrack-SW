import 'package:flutter/material.dart';

class TutorDashboard extends StatefulWidget {
  final int userId;
  const TutorDashboard({super.key, required this.userId});
  @override
  _TutorDashboardState createState() => _TutorDashboardState();
}

class _TutorDashboardState extends State<TutorDashboard> {
  // Datos temporales (Placeholders) mientras tu compañero termina la DB
  final String nombreHijo = "Diego Alejandro Marín"; 
  final double promedioGeneral = 9.2;
  final int totalAsistencias = 45;
  final int totalFaltas = 3;
  final int actividadesPendientes = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Panel del Tutor', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección: Información del Hijo
            _buildChildInfoCard(),
            SizedBox(height: 20),

            // Sección: Resumen Académico (Promedio y Asistencia)
            Text(
              "Resumen Académico",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildStatCard("Promedio", promedioGeneral.toString(), Icons.star, Colors.orange)),
                SizedBox(width: 10),
                Expanded(child: _buildStatCard("Asistencias", "$totalAsistencias", Icons.check_circle, Colors.green)),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildStatCard("Faltas", "$totalFaltas", Icons.cancel, Colors.red)),
                SizedBox(width: 10),
                Expanded(child: _buildStatCard("Actividades", "$actividadesPendientes", Icons.assignment, Colors.blue)),
              ],
            ),
            SizedBox(height: 25),

            // Sección: Acciones Rápidas
            Text(
              "Detalles y Seguimiento",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
            ),
            SizedBox(height: 15),
            _buildMenuOption("Ver Calificaciones Detalladas", Icons.list_alt, Colors.blue[800]!),
            _buildMenuOption("Historial de Asistencias", Icons.calendar_today, Colors.blue[700]!),
            _buildMenuOption("Justificar Faltas", Icons.upload_file, Colors.blue[600]!),
            _buildMenuOption("Información del Maestro", Icons.person_search, Colors.blue[500]!),
          ],
        ),
      ),
    );
  }

  // Widget para la tarjeta principal del alumno
  Widget _buildChildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.blue[900],
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tutor de:", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Text(
                    nombreHijo,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text("Grupo: TI-51", style: TextStyle(color: Colors.blue[900])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para las tarjetas de estadísticas (Promedio, Asistencias, etc)
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Widget para los botones de menú
  Widget _buildMenuOption(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Aquí navegaremos a las sub-vistas en los siguientes pasos
        },
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}