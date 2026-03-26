import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🟢 Conexión a la nube
import 'tutor_demo_data.dart';
import 'tutor_live_data_service.dart';
import 'tutor_ui.dart';

class TutorAttendanceScreen extends StatefulWidget {
  final TutorStudentSnapshot snapshot;
  final int userId;
  final String tutorName;

  const TutorAttendanceScreen({
    super.key,
    required this.snapshot,
    required this.userId,
    required this.tutorName,
  });

  @override
  State<TutorAttendanceScreen> createState() => _TutorAttendanceScreenState();
}

class _TutorAttendanceScreenState extends State<TutorAttendanceScreen> {
  late TutorStudentSnapshot _snapshot;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.snapshot;
  }

  Future<void> _refreshSnapshot() async {
    setState(() => _syncing = true);
    try {
      final latest = await TutorLiveDataService.loadSnapshot(
        sessionUserId: widget.userId,
        tutorName: widget.tutorName,
      );
      if (mounted) setState(() => _snapshot = latest);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWebWide = width >= 960;
    final isTablet = width >= 640;

    return Scaffold(
      backgroundColor: TutorPalette.bgLight,
      appBar: AppBar(
        title: const Text("Asistencia"),
        backgroundColor: TutorPalette.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('asistencias').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Map<String, dynamic>> misAsistencias = [];
          int asistenciasCount = 0;
          int faltasCount = 0;

          for (var doc in snapshot.data?.docs ?? []) {
            final data = doc.data() as Map<String, dynamic>;
            final detalles = data['detalles'] as List<dynamic>? ?? [];
            
            // 🟢 Buscamos al alumno en la lista
            final registroAlumno = detalles.firstWhere(
              (d) => d['alumnoId'] == widget.snapshot.studentId,
              orElse: () => null,
            );

            if (registroAlumno != null) {
              final String estado = registroAlumno['estado'] ?? 'desconocido';
              
              // 🛠️ ARREGLO DE LA FECHA (El problema del error rojo)
              String fechaFinal = 'Sin fecha';
              final rawFecha = data['fecha'];
              
              if (rawFecha is Timestamp) {
                // Si es Timestamp, lo convertimos a DateTime y luego a texto
                DateTime dt = rawFecha.toDate();
                fechaFinal = "${dt.day}/${dt.month}/${dt.year}"; 
              } else if (rawFecha is String) {
                // Si ya era texto, lo dejamos igual
                fechaFinal = rawFecha;
              }
              
              misAsistencias.add({
                'fecha': fechaFinal,
                'estado': estado,
                'nota': registroAlumno['nota'] ?? '',
              });

              if (estado.toLowerCase() == 'presente') asistenciasCount++;
              if (estado.toLowerCase() == 'falta') faltasCount++;
            }
          }

          double porcentaje = misAsistencias.isEmpty 
              ? 0.0 
              : (asistenciasCount / misAsistencias.length) * 100;

          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWebWide ? 1120 : double.infinity),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TutorPageHeader(
                        icon: Icons.calendar_month_rounded,
                        title: "Asistencia de ${_snapshot.studentName}",
                        subtitle: "Revisa el historial capturado por el maestro.",
                        trailing: TutorStatusBadge(text: "ID: ${widget.snapshot.studentId}", color: TutorPalette.primaryBlue),
                      ),
                      const SizedBox(height: 16),
                      // Tarjeta Hero con porcentaje real
                      _buildHeroCardReal(porcentaje),
                      const SizedBox(height: 16),
                      // Métricas reales
                      _buildMetricsGridReal(asistenciasCount, faltasCount, porcentaje, isWebWide, isTablet),
                      const SizedBox(height: 18),
                      tutorSectionTitle("Historial por fecha"),
                      const SizedBox(height: 12),
                      _buildHistoryListReal(misAsistencias),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🟢 MÉTODOS CON DATOS REALES (MANTENIENDO TU DISEÑO)

  Widget _buildHeroCardReal(double porcentaje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [TutorPalette.primaryBlue, TutorPalette.darkBlue]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${porcentaje.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
          const Text("Porcentaje de asistencia total", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMetricsGridReal(int a, int f, double p, bool w, bool t) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: w ? 3 : (t ? 2 : 1),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.5,
      ),
      children: [
        TutorMetricCard(value: "$a", label: "Asistencias", detail: "Días presente", icon: Icons.check_circle, tint: TutorPalette.success),
        TutorMetricCard(value: "$f", label: "Faltas", detail: "Inasistencias", icon: Icons.cancel, tint: TutorPalette.danger),
        TutorMetricCard(value: "${p.toStringAsFixed(0)}%", label: "Cumplimiento", detail: "Total", icon: Icons.pie_chart, tint: TutorPalette.primaryBlue),
      ],
    );
  }

  Widget _buildHistoryListReal(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) {
      return tutorEmptyStateCard(icon: Icons.calendar_month, title: "Sin registros", message: "No hay pases de lista para este alumno.");
    }
    return Column(
      children: lista.map((item) {
        final color = item['estado'].toString().toLowerCase() == 'presente' ? TutorPalette.success : TutorPalette.danger;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: tutorSurfaceDecoration(),
            child: Row(
              children: [
                Icon(Icons.event_note, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['fecha'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(item['nota'].toString().isEmpty ? "Sin observaciones" : item['nota'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                TutorStatusBadge(text: item['estado'].toString().toUpperCase(), color: color),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}