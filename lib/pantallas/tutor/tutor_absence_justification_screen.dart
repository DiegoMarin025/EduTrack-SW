import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/report_attachment_picker.dart';
import 'tutor_demo_data.dart';
import 'tutor_live_data_service.dart';
import 'tutor_ui.dart';
import '../../services/local_demo_store.dart'; 

class TutorAbsenceJustificationScreen extends StatefulWidget {
  final TutorStudentSnapshot snapshot;
  final int userId;
  final String tutorName;

  const TutorAbsenceJustificationScreen({
    super.key,
    required this.snapshot,
    required this.userId,
    required this.tutorName,
  });

  @override
  State<TutorAbsenceJustificationScreen> createState() =>
      _TutorAbsenceJustificationScreenState();
}

class _TutorAbsenceJustificationScreenState
    extends State<TutorAbsenceJustificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  List<String> _gruposFirebase = [];
  late TutorStudentSnapshot _currentSnapshot;
  late List<TutorJustificationRecord> _records;
  DateTime _manualDate = DateTime.now();
  String _manualSubject = '';
  SelectedReportAttachment? _selectedAttachment;
  int? _selectedIndex;
  bool _syncing = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _currentSnapshot = widget.snapshot;
    _records = const [];
    _applyRecords(widget.snapshot.justifications);
    _refreshSnapshot();
    _cargarGrupos(); // 🟢 Carga los grupos de la nube
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _cargarGrupos() async {
    try {
      final query = await FirebaseFirestore.instance.collection('grupos').get();
      setState(() {
        _gruposFirebase = query.docs.map((doc) => doc.data()['nombre'].toString()).toList();
      });
    } catch (e) {
      print("Error cargando grupos: $e");
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
        title: const Text("Justificacion de faltas"),
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
                    icon: Icons.approval_rounded,
                    title: "Justificacion de faltas",
                    subtitle: "Selecciona una falta, describe el motivo y envia la aclaracion.",
                  ),
                  const SizedBox(height: 16),
                  _buildHeroCard(isTablet),
                  const SizedBox(height: 18),
                  
                  tutorSectionTitle("Enviar nueva justificacion"),
                  const SizedBox(height: 12),
                  _buildFormCard(),
                  
                  const SizedBox(height: 24),
                  tutorSectionTitle("Tus envíos recientes"), // 🟢 Bandeja de enviados
                  const SizedBox(height: 12),
                  _buildEnviadosList(), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 SECCIÓN DE ENVIADOS (Filtra por Alumno ID)
  Widget _buildEnviadosList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('justificantes')
          .where('alumnoId', isEqualTo: widget.snapshot.studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error al cargar historial');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Text("No has enviado justificaciones aún.");

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return _buildJustificanteCard(data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildJustificanteCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(item['motivo'] ?? 'Justificación', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TutorStatusBadge(text: item['status'] ?? 'En revisión', color: Colors.amber),
            ],
          ),
          const SizedBox(height: 8),
          Text("Materia/Grupo: ${item['materia']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text("Detalle: ${item['detalle']}", style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: tutorSurfaceDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            InkWell(
              onTap: _sending ? null : _pickManualDate,
              child: InputDecorator(
                decoration: _inputDecoration("Fecha de la falta", Icons.calendar_month_rounded),
                child: Text(_formatManualDate(_manualDate)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _manualSubject.isEmpty ? null : _manualSubject,
              items: _gruposFirebase.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _manualSubject = val ?? ''),
              decoration: _inputDecoration("Selecciona el Grupo", Icons.group_work_rounded),
              validator: (v) => v == null ? "Requerido" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: _inputDecoration("Motivo", Icons.edit_note_rounded),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailController,
              maxLines: 3,
              decoration: _inputDecoration("Detalle", Icons.description_outlined),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            const SizedBox(height: 14),
            _buildAttachmentSection(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _submitJustification,
                style: ElevatedButton.styleFrom(backgroundColor: TutorPalette.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: _sending ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.send_rounded),
                label: Text(_sending ? "Enviando..." : "Enviar justificacion"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitJustification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final docRef = await FirebaseFirestore.instance.collection('justificantes').add({
        'alumnoId': widget.snapshot.studentId,
        'alumnoNombre': widget.snapshot.studentName,
        'tutorNombre': widget.tutorName,
        'tutorId': widget.userId,
        'motivo': _reasonController.text.trim(),
        'detalle': _detailController.text.trim(),
        'materia': _manualSubject,
        'fecha': _formatManualDate(_manualDate),
        'status': "En revision",
        'createdAt': FieldValue.serverTimestamp(),
        'hasAttachment': _selectedAttachment != null,
        'profesorId': "qcT8HBPWnNQpRMGl3O32vudf1X2", 
      });

      if (_selectedAttachment != null) {
        LocalDemoStore.justificantesLocales[docRef.id] = _selectedAttachment;
      }

      _reasonController.clear();
      _detailController.clear();
      setState(() { _sending = false; _selectedAttachment = null; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Enviado")));
    } catch (e) {
      setState(() => _sending = false);
    }
  }

  // --- MÉTODOS DE APOYO (REQUERIDOS) ---
  InputDecoration _inputDecoration(String l, IconData i) => InputDecoration(labelText: l, prefixIcon: Icon(i, color: TutorPalette.primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
  
  Widget _buildAttachmentSection() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: TutorPalette.border)),
    child: Row(
      children: [
        const Icon(Icons.attach_file, color: TutorPalette.primaryBlue),
        const SizedBox(width: 8),
        Expanded(child: Text(_selectedAttachment == null ? 'Adjuntar comprobante' : _selectedAttachment!.fileName)),
        TextButton(onPressed: _pickAttachment, child: const Text('Adjuntar')),
      ],
    ),
  );

  Future<void> _pickAttachment() async {
    final s = await pickReportAttachment();
    if (s != null) setState(() => _selectedAttachment = s);
  }

  Future<void> _pickManualDate() async {
    final p = await showDatePicker(context: context, initialDate: _manualDate, firstDate: DateTime(2025), lastDate: DateTime(2026));
    if (p != null) setState(() => _manualDate = p);
  }

  String _formatManualDate(DateTime v) {
    const m = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${v.day} ${m[v.month - 1]} ${v.year}';
  }

  void _applyRecords(List<TutorJustificationRecord> r) { _records = List.from(r); }
  Future<void> _refreshSnapshot() async { /* Lógica de refresco */ }
  int _pendingCount() => _records.length;
  int _approvedCount() => 0;
  int _reviewCount() => 0;

  Widget _buildHeroCard(bool t) => Container(height: 80, decoration: BoxDecoration(color: TutorPalette.primaryBlue, borderRadius: BorderRadius.circular(20)), child: const Center(child: Text("Panel de Control", style: TextStyle(color: Colors.white))));
  Widget _buildMetricsGrid(bool w, bool t) => const SizedBox.shrink();
  Widget _buildHistoryList() => const SizedBox.shrink();
  Widget _heroPill({required IconData icon, required String title, required String subtitle}) => const SizedBox.shrink();
}