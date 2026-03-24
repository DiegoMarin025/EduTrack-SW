import 'package:flutter/material.dart';

import '../../services/report_attachment_picker.dart';
import 'tutor_demo_data.dart';
import 'tutor_live_data_service.dart';
import 'tutor_ui.dart';

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
  }

  @override
  void dispose() {
    _reasonController.dispose();
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
        title: const Text("Justificacion de faltas"),
        backgroundColor: TutorPalette.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Actualizar",
            onPressed: _syncing ? null : _refreshSnapshot,
            icon: _syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWebWide ? 1120 : double.infinity,
            ),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWebWide ? 28 : 20,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TutorPageHeader(
                    icon: Icons.approval_rounded,
                    title: "Justificacion de faltas",
                    subtitle:
                        "Selecciona una falta, describe el motivo y envia la aclaracion.",
                    trailing: TutorStatusBadge(
                      text: "${_pendingCount()} pendientes",
                      color: TutorPalette.warning,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHeroCard(isTablet),
                  const SizedBox(height: 16),
                  _buildMetricsGrid(isWebWide, isTablet),
                  const SizedBox(height: 18),
                  tutorSectionTitle("Enviar justificacion"),
                  const SizedBox(height: 12),
                  _buildFormCard(),
                  const SizedBox(height: 18),
                  tutorSectionTitle("Faltas registradas"),
                  const SizedBox(height: 12),
                  _buildHistoryList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isTablet) {
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            "CONTROL DE JUSTIFICACIONES",
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
          "Mantiene al dia las aclaraciones por inasistencia para evitar pendientes administrativos.",
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
          icon: Icons.pending_actions_rounded,
          title: "${_pendingCount()}",
          subtitle: "Pendientes",
        ),
        _heroPill(
          icon: Icons.task_alt_rounded,
          title: "${_approvedCount()}",
          subtitle: "Aprobadas",
        ),
        _heroPill(
          icon: Icons.search_rounded,
          title: "${_reviewCount()}",
          subtitle: "En revision",
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
                  Expanded(child: detail),
                  const SizedBox(width: 14),
                  pills,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [detail, const SizedBox(height: 16), pills],
              ),
      ),
    );
  }

  Widget _buildMetricsGrid(bool isWebWide, bool isTablet) {
    final metrics = [
      TutorMetricCard(
        value: "${_records.length}",
        label: "Faltas registradas",
        detail: "Casos visibles en el historial",
        icon: Icons.event_busy_rounded,
        tint: TutorPalette.danger,
      ),
      TutorMetricCard(
        value: "${_pendingCount()}",
        label: "Pendientes",
        detail: "Listas para enviar o completar",
        icon: Icons.pending_actions_rounded,
        tint: TutorPalette.warning,
      ),
      TutorMetricCard(
        value: "${_approvedCount()}",
        label: "Aprobadas",
        detail: "Validadas por la escuela",
        icon: Icons.verified_rounded,
        tint: TutorPalette.success,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWebWide ? 3 : (isTablet ? 2 : 1),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWebWide ? 2.2 : (isTablet ? 2.2 : 2.8),
      ),
      itemBuilder: (context, index) => metrics[index],
    );
  }

  Widget _buildFormCard() {
    final availableSubjects = _availableSubjects();

    final dropdownItems = List.generate(_records.length, (index) {
      final record = _records[index];
      return DropdownMenuItem<int>(
        value: index,
        child: Text("${record.dateLabel} | ${record.subjectName}"),
      );
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: tutorSurfaceDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Registro de justificacion",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: TutorPalette.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Completa el motivo y envia la aclaracion al maestro para su revision.",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TutorPalette.textSoft,
              ),
            ),
            const SizedBox(height: 14),
            if (_records.isNotEmpty) ...[
              DropdownButtonFormField<int>(
                initialValue: _selectedIndex,
                items: dropdownItems,
                onChanged: (value) {
                  setState(() {
                    _selectedIndex = value;
                    if (value != null) {
                      _reasonController.text = _records[value].reason;
                      _detailController.text = _records[value].detail;
                    }
                  });
                },
                decoration: _inputDecoration(
                  "Falta a justificar",
                  Icons.event_busy_rounded,
                ),
                validator: (value) {
                  if (_records.isNotEmpty && value == null) {
                    return "Selecciona una falta";
                  }
                  return null;
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TutorPalette.primaryBlue),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: TutorPalette.primaryBlue,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Todavia no aparece una falta en el historial, pero ya puedes enviar la justificacion manual para que el maestro la revise.",
                        style: TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w600,
                          color: TutorPalette.textSoft,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _sending ? null : _pickManualDate,
                child: InputDecorator(
                  decoration: _inputDecoration(
                    "Fecha de la falta",
                    Icons.calendar_month_rounded,
                  ),
                  child: Text(
                    _formatManualDate(_manualDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TutorPalette.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _manualSubject,
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Sin materia especifica'),
                  ),
                  ...availableSubjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject),
                    );
                  }),
                ],
                onChanged: _sending
                    ? null
                    : (value) {
                        setState(() {
                          _manualSubject = value ?? '';
                        });
                      },
                decoration: _inputDecoration(
                  "Materia relacionada",
                  Icons.menu_book_rounded,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: _inputDecoration("Motivo", Icons.edit_note_rounded),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Escribe el motivo";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailController,
              maxLines: 4,
              decoration: _inputDecoration(
                "Detalle o soporte",
                Icons.description_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Agrega una explicacion breve";
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildAttachmentSection(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _submitJustification,
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
                  _sending ? "Enviando..." : "Enviar justificacion",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_records.isEmpty) {
      return tutorEmptyStateCard(
        icon: Icons.event_busy_rounded,
        title: "Aqui apareceran las faltas registradas",
        message:
            "Esta seccion mostrara las inasistencias y su estatus de revision cuando haya informacion disponible.",
      );
    }

    return Column(
      children: List.generate(_records.length, (index) {
        final record = _records[index];
        final color = tutorStatusColor(record.status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                _selectedIndex = index;
                _reasonController.text = record.reason;
                _detailController.text = record.detail;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: tutorSurfaceDecoration(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.event_busy_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${record.dateLabel} | ${record.subjectName}",
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: TutorPalette.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          record.reason,
                          style: const TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w700,
                            color: TutorPalette.textSoft,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          record.detail,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TutorPalette.textSoft,
                            height: 1.45,
                          ),
                        ),
                        if (record.hasAttachment) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: TutorPalette.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.attach_file_rounded,
                                  size: 16,
                                  color: TutorPalette.primaryBlue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    record.attachmentName.trim().isNotEmpty
                                        ? record.attachmentName
                                        : 'Comprobante adjunto',
                                    style: const TextStyle(
                                      fontSize: 12.4,
                                      fontWeight: FontWeight.w700,
                                      color: TutorPalette.textDark,
                                    ),
                                  ),
                                ),
                                if (record.attachmentSizeBytes > 0)
                                  Text(
                                    _formatAttachmentSize(
                                      record.attachmentSizeBytes,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: TutorPalette.textSoft,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  TutorStatusBadge(text: record.status, color: color),
                ],
              ),
            ),
          ),
        );
      }),
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
                  'Adjunta un comprobante en PDF o imagen. Maximo 10 MB.',
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

  Future<void> _submitJustification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    TutorJustificationRecord? targetRecord;
    if (_records.isNotEmpty) {
      if (_selectedIndex == null) {
        return;
      }
      targetRecord = _records[_selectedIndex!];
    } else {
      targetRecord = TutorJustificationRecord(
        dateLabel: _manualDate.toIso8601String().split('T').first,
        subjectName: _manualSubject,
        status: "En revision",
        reason: _reasonController.text.trim(),
        detail: _detailController.text.trim(),
      );
    }

    if (targetRecord == null) {
      return;
    }

    setState(() => _sending = true);

    final updatedRecord = targetRecord.copyWith(
      reason: _reasonController.text.trim(),
      detail: _detailController.text.trim(),
      status: "En revision",
    );

    final sent = await TutorLiveDataService.submitAbsenceJustification(
      usuarioId: widget.userId,
      record: updatedRecord,
      reason: _reasonController.text.trim(),
      detail: _detailController.text.trim(),
      attachment: _selectedAttachment,
    );

    if (!mounted) {
      return;
    }

    setState(() => _sending = false);

    if (sent) {
      setState(() => _selectedAttachment = null);
      await _refreshSnapshot();
    } else {
      if (_records.isNotEmpty && _selectedIndex != null) {
        setState(() {
          _records[_selectedIndex!] = updatedRecord.copyWith(
            status: "Pendiente",
          );
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? "La justificacion se envio al maestro para revision."
              : "No se pudo enviar la justificacion al maestro. Revisa la vinculacion del tutor.",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refreshSnapshot() async {
    setState(() => _syncing = true);

    try {
      final snapshot = await TutorLiveDataService.loadSnapshot(
        sessionUserId: widget.userId,
        tutorName: widget.tutorName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentSnapshot = snapshot;
        _applyRecords(snapshot.justifications);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar la lista de faltas: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  void _applyRecords(List<TutorJustificationRecord> records) {
    _records = List<TutorJustificationRecord>.from(records);

    if (_records.isEmpty) {
      _selectedIndex = null;
      _reasonController.clear();
      _detailController.clear();
      return;
    }

    final pendingIndex = _records.indexWhere(
      (record) => record.status == "Pendiente",
    );
    final fallbackIndex = pendingIndex >= 0 ? pendingIndex : 0;
    _selectedIndex = fallbackIndex;
    _reasonController.text = _records[fallbackIndex].reason;
    _detailController.text = _records[fallbackIndex].detail;
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
            content: Text(
              'El comprobante excede el maximo permitido de 10 MB.',
            ),
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
        SnackBar(content: Text('No se pudo adjuntar el comprobante: $error')),
      );
    }
  }

  Future<void> _pickManualDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _manualDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked != null) {
      setState(() => _manualDate = picked);
    }
  }

  List<String> _availableSubjects() {
    final subjects = <String>{};

    final currentManualSubject = _manualSubject.trim();
    if (currentManualSubject.isNotEmpty) {
      subjects.add(currentManualSubject);
    }

    for (final record in _records) {
      final subject = record.subjectName.trim();
      if (subject.isNotEmpty && subject.toLowerCase() != 'materia') {
        subjects.add(subject);
      }
    }

    for (final grade in _currentSnapshot.grades) {
      final subject = grade.subjectName.trim();
      if (subject.isNotEmpty) {
        subjects.add(subject);
      }
    }

    for (final activity in _currentSnapshot.activities) {
      final subject = activity.subjectName.trim();
      if (subject.isNotEmpty) {
        subjects.add(subject);
      }
    }

    for (final comment in _currentSnapshot.comments) {
      final subject = comment.subjectName.trim();
      if (subject.isNotEmpty) {
        subjects.add(subject);
      }
    }

    final ordered = subjects.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ordered;
  }

  String _formatManualDate(DateTime value) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return '${value.day} ${months[(value.month - 1).clamp(0, 11)]} ${value.year}';
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

  int _pendingCount() {
    return _records.where((record) => record.status == "Pendiente").length;
  }

  int _approvedCount() {
    return _records.where((record) => record.status == "Aprobada").length;
  }

  int _reviewCount() {
    return _records.where((record) => record.status == "En revision").length;
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
