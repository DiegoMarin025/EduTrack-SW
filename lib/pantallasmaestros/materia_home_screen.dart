import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- LA NUBE
import '../services/api_service.dart';
import 'detalle_grupo_screen.dart';
import 'subir_calificaciones_screen.dart';
import 'teacher_navigation_helper.dart';

class MateriaHomeScreen extends StatefulWidget {
  final String nombreGrupo; 
  final int grupoIdReal; 
  final String materia; 
  final Grupo representative; 

  const MateriaHomeScreen({
    super.key,
    required this.nombreGrupo,
    required this.grupoIdReal,
    required this.materia,
    required this.representative,
  });

  @override
  State<MateriaHomeScreen> createState() => _MateriaHomeScreenState();
}

class _MateriaHomeScreenState extends State<MateriaHomeScreen> {
  final Color primaryBlue = const Color(0xFF2D63ED);
  bool _loading = true;
  List<Alumno> _alumnos = [];

  @override
  void initState() {
    super.initState();
    _cargarAlumnosFirebase(); // <--- Cambiamos a la versión nube
  }

  // ======================================================
  // 💾 CARGAR ALUMNOS DESDE FIREBASE
  // ======================================================
  Future<void> _cargarAlumnosFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('alumnos')
          .where('grupoId', isEqualTo: widget.representative.grupoIdReal)
          .get();

      final listaAlumnos = snapshot.docs.map((doc) {
        final data = doc.data();
        return Alumno(
          id: data['id'] ?? doc.id.hashCode,
          nombre: data['nombre'] ?? 'Sin nombre',
          correo: data['correo'] ?? '',
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _alumnos = listaAlumnos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _alumnos = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando alumnos: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _abrirCalificacionesRapidas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SubirCalificacionesScreen(initialGrupoId: widget.representative.id),
      ),
    );
  }

  Future<void> _abrirPasarLista() async {
    await TeacherNavigationHelper.openAttendanceForRepresentative(
      context: context,
      representative: widget.representative,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = "${widget.nombreGrupo} - ${widget.materia}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ActionCard(
                    icon: Icons.people_alt_rounded,
                    title: "Ver alumnos",
                    subtitle: "Lista del grupo y gestión de alumnos",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DetalleGrupoScreen(grupo: widget.representative),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.grade_rounded,
                    title: "Calificaciones",
                    subtitle: "Actividades, entregas y cierre final",
                    onTap: _abrirCalificacionesRapidas,
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.checklist_rounded,
                    title: "Pasar lista",
                    subtitle: "Registro de asistencia por día",
                    onTap: _alumnos.isEmpty ? null : _abrirPasarLista, // ¡Ahora sí tendrá alumnos!
                  ),
                ],
              ),
            ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFF2D63ED).withOpacity(0.10)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: enabled
                    ? const Color(0xFF2D63ED)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: enabled ? Colors.grey[500] : Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}
