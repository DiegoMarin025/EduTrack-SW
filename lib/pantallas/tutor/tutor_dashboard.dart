import 'package:flutter/material.dart';
import 'tutor_grades_screen.dart';

class TutorDashboard extends StatefulWidget {
  final int userId;
  final String username;

  const TutorDashboard({super.key, required this.userId, required this.username});

  @override
  _TutorDashboardState createState() => _TutorDashboardState();
}

class _TutorDashboardState extends State<TutorDashboard> {
  final String nombreHijo = "Diego Alejandro Marín";
  final String grupoHijo = "TI-51";
  final double promedioGeneral = 9.2;
  final int totalAsistencias = 45;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA), // Fondo gris claro de la imagen
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0), // Más padding general
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN GENERAL (Sin Scaffold ni AppBar) ---
            _buildTopHeader(),
            const SizedBox(height: 25),
            _buildMainBlueCard(),
            const SizedBox(height: 25),
            
            // Stats (Se mantienen grandes)
            Row(
              children: [
                Expanded(child: _buildMiniStatCard("Promedio", "$promedioGeneral", Icons.star_border, Colors.blue)),
                const SizedBox(width: 20),
                Expanded(child: _buildMiniStatCard("Asistencias", "$totalAsistencias", Icons.people_outline, Colors.green)),
              ],
            ),
            const SizedBox(height: 40),

            const Text(
              "Acciones rápidas",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A337E)),
            ),
            const SizedBox(height: 20),
            
            // --- GRID DE ACCIONES RÁPIDAS (Corregido: 4 grandes en fila) ---
            GridView.count(
              crossAxisCount: 4, // 4 columnas
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              // Relación Ancho/Alto para Web (Mayor para que no se estiren hacia abajo)
              childAspectRatio: 1.4, 
              children: [
                _buildActionCard(
                  "Asistencia", 
                  "Pase de lista", 
                  Icons.person_add_alt_1, 
                  Colors.blue,
                  onTap: () => print("Asistencia"),
                ),
                _buildActionCard(
                  "Calificaciones", 
                  "Evaluar rápido", 
                  Icons.star_outline, 
                  Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TutorGradesScreen()),
                    );
                  },
                ),
                _buildActionCard(
                  "Mis grupos", 
                  "Alumnos y listas", 
                  Icons.assignment_outlined, 
                  Colors.green,
                  onTap: () => print("Grupos"),
                ),
                _buildActionCard(
                  "Reportes", 
                  "Resumen semanal", 
                  Icons.bar_chart, 
                  Colors.purple,
                  onTap: () => print("Reportes"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES DE DISEÑO ---

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              radius: 26,
              child: const Icon(Icons.school, color: Color(0xFF1A337E), size: 26),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "¡Hola, ${widget.username.toLowerCase()}!",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A337E)),
                ),
                const Text("Bienvenido a tu panel de control", style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Color(0xFF1A337E)),
              SizedBox(width: 10),
              Text("Vie 20 Mar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainBlueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2855D1), Color(0xFF1A337E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.menu_book, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Resumen del alumno", style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(nombreHijo, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Grupo $grupoHijo", style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // MÉTODO ACTUALIZADO: CAJAS GRANDES Y LEGIBLES
  // ------------------------------------------------------------------
  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          // --- AUMENTAMOS PADDING INTERNO ---
          padding: const EdgeInsets.all(24), 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alineación a la izquierda
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                // --- AUMENTAMOS TAMAÑO DEL ICONO ---
                child: Icon(icon, color: color, size: 30), 
              ),
              const SizedBox(height: 15),
              // --- AUMENTAMOS TAMAÑO DE FUENTE ---
              Text(
                title, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A337E)),
              ),
              const SizedBox(height: 4),
              // --- AUMENTAMOS TAMAÑO DE SUBTÍTULO ---
              Text(
                subtitle, 
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}