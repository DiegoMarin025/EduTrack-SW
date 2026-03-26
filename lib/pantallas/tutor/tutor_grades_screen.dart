import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tutor_demo_data.dart';
import 'tutor_live_data_service.dart';
import 'tutor_ui.dart';

class TutorGradesScreen extends StatefulWidget {
  final TutorStudentSnapshot snapshot;
  final int userId;
  final String tutorName;

  const TutorGradesScreen({
    super.key,
    required this.snapshot,
    required this.userId,
    required this.tutorName,
  });

  @override
  State<TutorGradesScreen> createState() => _TutorGradesScreenState();
}

class _TutorGradesScreenState extends State<TutorGradesScreen> {
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
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWebWide = width >= 960;

    return Scaffold(
      backgroundColor: TutorPalette.bgLight,
      appBar: AppBar(
        title: const Text("Calificaciones", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: TutorPalette.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
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
                    icon: Icons.grade_rounded,
                    title: "Calificaciones de ${_snapshot.studentName}",
                    subtitle: "Consulta las notas registradas por materia.",
                  ),
                  const SizedBox(height: 16),
                  _buildHeroCard(),
                  const SizedBox(height: 24),
                  tutorSectionTitle("Promedio por materia"),
                  const SizedBox(height: 12),
                  _buildSubjectCards(), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCards() {
    return StreamBuilder<QuerySnapshot>(
      // 🟢 USAMOS EL ID DINÁMICO DEL ALUMNO
      stream: FirebaseFirestore.instance
          .collection('calificaciones')
          .where('alumnoId', isEqualTo: widget.snapshot.studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error de conexión");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return tutorEmptyStateCard(
            icon: Icons.grade_rounded,
            title: "Sin registros",
            message: "No hay calificaciones para el ID: ${widget.snapshot.studentId}",
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final calif = data['calificacion'] ?? 0;
            final materia = data['materia'] ?? 'Materia';
            
            final cardColor = calif >= 9 ? Colors.green : (calif >= 8 ? Colors.blue : Colors.orange);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TutorPalette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(14)
                    ),
                    child: Icon(Icons.book_outlined, color: cardColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(materia, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text("Evaluación parcial", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardColor, 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Text(
                      calif.toString(),
                      // 🟢 ARREGLADO: FontWeight.w900 en lugar de .black
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 16
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [TutorPalette.primaryBlue, TutorPalette.darkBlue]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Text("Resumen Academico", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          SizedBox(height: 8),
          Text("Enterate de las calificaciones de tu hij@", 
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}