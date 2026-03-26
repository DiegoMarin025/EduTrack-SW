import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/report_attachment_picker.dart';
import 'tutor_demo_data.dart';
import 'tutor_live_data_service.dart';
import 'tutor_ui.dart';
import '../../services/local_demo_store.dart'; 

class TutorTeacherReportScreen extends StatefulWidget {
  final TutorStudentSnapshot snapshot;
  final int userId;

  // 🟢 Quitamos el tutorName de aquí para que NO te de error en las otras pantallas
  const TutorTeacherReportScreen({
    super.key,
    required this.snapshot,
    required this.userId,
  });

  @override
  State<TutorTeacherReportScreen> createState() =>
      _TutorTeacherReportScreenState();
}

class _TutorTeacherReportScreenState extends State<TutorTeacherReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  static const List<String> _categories = [
    'Reporte academico',
    'Seguimiento',
    'Conducta',
    'Solicitud de reunion',
    'Denuncia formal',
  ];

  late String _selectedCategory;
  String _selectedSubject = 'General';
  SelectedReportAttachment? _selectedAttachment;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  // ☁️ ENVÍO A FIREBASE
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    try {
      final docRef = await FirebaseFirestore.instance.collection('reportes_seguimiento').add({
        'alumnoId': widget.snapshot.studentId,
        'alumnoNombre': widget.snapshot.studentName,
        'tutorId': widget.userId,
        'categoria': _selectedCategory,
        'asunto': _titleController.text.trim(),
        'detalle': _detailController.text.trim(),
        'materia': _selectedSubject,
        'status': 'En revision por direccion',
        'createdAt': FieldValue.serverTimestamp(),
        'hasAttachment': _selectedAttachment != null,
        'profesorId': "qcT8HBPWnNQpRMGl3O32vudf1X2", 
      });

      if (_selectedAttachment != null) {
        LocalDemoStore.justificantesLocales[docRef.id] = _selectedAttachment;
      }

      _titleController.clear();
      _detailController.clear();
      setState(() {
        _sending = false;
        _selectedAttachment = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte enviado correctamente")),
      );
    } catch (e) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWebWide = width >= 960;

    return Scaffold(
      backgroundColor: TutorPalette.bgLight,
      appBar: AppBar(
        title: const Text("Reportar al maestro"),
        backgroundColor: TutorPalette.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TutorPageHeader(
                icon: Icons.campaign_rounded,
                title: "Reporte para el maestro",
                subtitle: "Envía una incidencia formal a la dirección.",
              ),
              const SizedBox(height: 16),
              _buildFormCard(),
              const SizedBox(height: 24),
              tutorSectionTitle("Historial de reportes"),
              const SizedBox(height: 12),
              _buildSentReportsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final subjectOptions = ['General', ...widget.snapshot.grades.map((g) => g.subjectName)];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: tutorSurfaceDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
              decoration: _inputDecoration("Categoria", Icons.category_rounded),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration("Asunto", Icons.title_rounded),
              validator: (v) => v!.isEmpty ? "Campo requerido" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailController,
              maxLines: 4,
              decoration: _inputDecoration("Detalle", Icons.description_outlined),
              validator: (v) => v!.isEmpty ? "Campo requerido" : null,
            ),
            const SizedBox(height: 14),
            _buildAttachmentSection(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TutorPalette.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                ),
                icon: _sending ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.send_rounded),
                label: const Text("Enviar reporte formal", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentReportsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reportes_seguimiento')
          .where('alumnoId', isEqualTo: widget.snapshot.studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Text("No hay reportes enviados.");

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.gavel_rounded, color: Colors.redAccent),
                title: Text(data['asunto'] ?? 'Sin asunto', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Status: ${data['status']}"),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String l, IconData i) => InputDecoration(
    labelText: l, prefixIcon: Icon(i, color: TutorPalette.primaryBlue),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    filled: true, fillColor: const Color(0xFFF8FAFC),
  );

  Widget _buildAttachmentSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: TutorPalette.border)),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: TutorPalette.primaryBlue),
          const SizedBox(width: 8),
          Expanded(child: Text(_selectedAttachment == null ? 'Evidencia (opcional)' : _selectedAttachment!.fileName, style: const TextStyle(fontSize: 12))),
          TextButton(onPressed: _pickAttachment, child: const Text('Subir')),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final s = await pickReportAttachment();
    if (s != null) setState(() => _selectedAttachment = s);
  }
}