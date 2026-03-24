import 'package:flutter/material.dart';

import '../../services/report_attachment_picker.dart';
import 'tutor_demo_data.dart';
import 'tutor_live_data_service.dart';
import 'tutor_ui.dart';

class TutorTeacherReportScreen extends StatefulWidget {
  final TutorStudentSnapshot snapshot;
  final int userId;

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWebWide = width >= 960;
    final isTablet = width >= 640;

    return Scaffold(
      backgroundColor: TutorPalette.bgLight,
      appBar: AppBar(
        title: const Text("Reportar al maestro"),
        backgroundColor: TutorPalette.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWebWide ? 1120 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWebWide ? 28 : 20,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TutorPageHeader(
                    icon: Icons.campaign_rounded,
                    title: "Seguimiento para ${widget.snapshot.studentName}",
                    subtitle:
                        "Envia un reporte al maestro sobre calificaciones, seguimiento o una reunion.",
                    trailing: TutorStatusBadge(
                      text: "${widget.snapshot.reportsCount} enviados",
                      color: TutorPalette.info,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHeroCard(isTablet),
                  const SizedBox(height: 18),
                  tutorSectionTitle("Nuevo reporte"),
                  const SizedBox(height: 12),
                  _buildFormCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isTablet) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            "COMUNICACION CON DOCENTES",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "Usa este espacio para compartir seguimiento academico, solicitar reunion o levantar una observacion puntual.",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ],
    );

    final pills = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _heroPill(
          icon: Icons.person_rounded,
          title: widget.snapshot.studentName,
          subtitle: "Alumno",
        ),
        _heroPill(
          icon: Icons.menu_book_rounded,
          title: "${widget.snapshot.grades.length}",
          subtitle: "Materias",
        ),
        _heroPill(
          icon: Icons.description_outlined,
          title: "${widget.snapshot.reportsCount}",
          subtitle: "Reportes",
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TutorPalette.primaryBlue, TutorPalette.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TutorPalette.primaryBlue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: isTablet
            ? Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 14),
                  Flexible(child: pills),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [details, const SizedBox(height: 16), pills],
              ),
      ),
    );
  }

  Widget _buildFormCard() {
    final subjectOptions = [
      'General',
      ...widget.snapshot.grades.map((grade) => grade.subjectName),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: tutorSurfaceDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reporte para el maestro",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: TutorPalette.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Selecciona la categoria, agrega un asunto claro y describe el seguimiento que necesita revision.",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TutorPalette.textSoft,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
              decoration: _inputDecoration("Categoria", Icons.category_rounded),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
              items: subjectOptions
                  .map(
                    (subject) => DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSubject = value);
                }
              },
              decoration: _inputDecoration("Materia", Icons.menu_book_rounded),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration("Asunto", Icons.title_rounded),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Escribe un asunto";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailController,
              maxLines: 5,
              decoration: _inputDecoration(
                "Detalle del reporte",
                Icons.description_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Agrega el detalle para el maestro";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildAttachmentSection(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TutorPalette.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _sending ? "Enviando..." : "Enviar reporte",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TutorPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.attach_file_rounded,
                color: TutorPalette.primaryBlue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Adjunta un comprobante o evidencia en PDF o imagen. Maximo 10 MB.',
                  style: TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                    color: TutorPalette.textSoft,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _sending ? null : _pickAttachment,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                  _selectedAttachment == null ? 'Adjuntar' : 'Cambiar',
                ),
              ),
            ],
          ),
          if (_selectedAttachment != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TutorPalette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TutorPalette.primaryBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: TutorPalette.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAttachment!.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: TutorPalette.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatAttachmentSize(_selectedAttachment!.sizeBytes),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: TutorPalette.textSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar archivo',
                    onPressed: _sending
                        ? null
                        : () {
                            setState(() => _selectedAttachment = null);
                          },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: TutorPalette.textSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: TutorPalette.primaryBlue),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TutorPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TutorPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TutorPalette.primaryBlue),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _sending = true);

    final sent = await TutorLiveDataService.submitTeacherReport(
      userId: widget.userId,
      category: _selectedCategory,
      title: _titleController.text.trim(),
      detail: _detailController.text.trim(),
      subjectName: _selectedSubject == 'General' ? null : _selectedSubject,
      attachment: _selectedAttachment,
    );

    if (!mounted) {
      return;
    }

    setState(() => _sending = false);

    if (sent) {
      setState(() => _selectedAttachment = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El reporte se envio al maestro correctamente."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "No se pudo enviar el reporte. Revisa la vinculacion del tutor y la conexion al backend.",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final selected = await pickReportAttachment();
      if (!mounted || selected == null) {
        return;
      }

      if (selected.sizeBytes > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo excede el maximo permitido de 10 MB.'),
          ),
        );
        return;
      }

      setState(() => _selectedAttachment = selected);
    } on UnsupportedError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? '$error')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo adjuntar la evidencia: $error')),
      );
    }
  }

  String _formatAttachmentSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _heroPill({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
