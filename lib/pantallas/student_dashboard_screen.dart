import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/api_service.dart'; // Conexión real a datos

class StudentDashboardScreen extends StatefulWidget {
  final int userId;

  const StudentDashboardScreen({super.key, required this.userId});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  DashboardData? dashboardData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  // Carga datos reales desde la API, llama a la api
  void _loadAcademicData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    //llama a l backend
    try {
      DashboardData data = await ApiService.getStudentDashboard(widget.userId);
      if (mounted) {
        setState(() {
          dashboardData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF673AB7)),
            )
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(errorMessage!, textAlign: TextAlign.center),
                  ),
                  ElevatedButton(
                    onPressed: _loadAcademicData,
                    child: const Text("Reintentar"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: AverageCircleWidget(
                        average: dashboardData!.average,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AcademicDetailsSection(data: dashboardData!),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

// Widget circular del promedio
class AverageCircleWidget extends StatelessWidget {
  final double average;
  const AverageCircleWidget({super.key, required this.average});

  @override
  Widget build(BuildContext context) {
    final double percent = (average / 10.0).clamp(0.0, 1.0);
    String ratingText;
    Color progressColor;

    if (average >= 9.1) {
      ratingText = 'Excelente';
      progressColor = const Color(0xFF4CAF50);
    } else if (average >= 8.1) {
      ratingText = 'Muy Bien';
      progressColor = const Color(0xFF2196F3);
    } else if (average >= 7.0) {
      ratingText = 'Bien';
      progressColor = const Color(0xFFFFC107);
    } else {
      ratingText = 'Reprobatoria';
      progressColor = const Color(0xFFF44336);
    }

    return CircularPercentIndicator(
      radius: 100.0,
      lineWidth: 15.0,
      percent: percent,
      progressColor: progressColor,
      backgroundColor: const Color(0xFFF0F0F5),
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 1000,
      center: Container(
        width: 170,
        height: 170,
        decoration: const BoxDecoration(
          color: Color(0xFF673AB7),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              average.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 50,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Promedio general',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ratingText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sección de detalles académicos
class AcademicDetailsSection extends StatelessWidget {
  final DashboardData data;
  const AcademicDetailsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Detalles académicos',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 3,
          ),
        ),

        _buildDetailRow(Icons.person, 'Alumno: ${data.student.nombre}'),
        const SizedBox(height: 10),

        _buildDetailRow(
          Icons.assignment_ind_outlined,
          'ID: ${data.student.matricula}',
        ),

        const SizedBox(height: 25),

        const Text(
          'Materias Activas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 2,
          ),
        ),
        const SizedBox(height: 10),

        if (data.subjects.isEmpty)
          const Text(
            "No tienes materias activas.",
            style: TextStyle(color: Colors.grey),
          )
        else
          ...data.subjects.map((s) => _buildSubjectItem(s)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF673AB7), size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectItem(Subject subject) {
    String info = subject.estado;
    Color colorInfo = subject.estado == 'Aprobada'
        ? Colors.green
        : (subject.estado == 'Reprobada' ? Colors.red : Colors.grey);
    String displayText = subject.materia;
    if (subject.calificacion != null)
      displayText += ' (${subject.calificacion})';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayText,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          Text(
            info,
            style: TextStyle(
              color: colorInfo,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
