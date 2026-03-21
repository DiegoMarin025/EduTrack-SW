import 'package:flutter/material.dart';

import 'tutor_demo_data.dart';
import 'tutor_live_data_service.dart';
import 'tutor_ui.dart';

class TutorAbsenceJustificationScreen extends StatefulWidget {
  final TutorStudentSnapshot snapshot;
  final int userId;

  const TutorAbsenceJustificationScreen({
    super.key,
    required this.snapshot,
    required this.userId,
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

  late List<TutorJustificationRecord> _records;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Fuente temporal: las justificaciones viven hoy en el snapshot local.
    // Cuando exista origen real, precargar _records desde backend/Firebase aqui.
    _records = List<TutorJustificationRecord>.from(
      widget.snapshot.justifications,
    );

    final pendingIndex = _records.indexWhere(
      (record) => record.status == "Pendiente",
    );

    if (pendingIndex >= 0) {
      _selectedIndex = pendingIndex;
      _reasonController.text = _records[pendingIndex].reason;
      _detailController.text = _records[pendingIndex].detail;
    }
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
                children: [
                  detail,
                  const SizedBox(height: 16),
                  pills,
                ],
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
    // El formulario ya esta listo para trabajar con datos reales.
    // La parte que falta conectar de verdad es el guardado/actualizacion del documento.
    if (_records.isEmpty) {
      return tutorEmptyStateCard(
        icon: Icons.approval_rounded,
        title: "Aqui podras justificar faltas",
        message:
            "Cuando existan faltas registradas del alumno, este formulario permitira enviar la aclaracion correspondiente.",
      );
    }

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
              "Completa el motivo y envia la aclaracion para la falta seleccionada.",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TutorPalette.textSoft,
              ),
            ),
            const SizedBox(height: 14),
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
                if (value == null) {
                  return "Selecciona una falta";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: _inputDecoration(
                "Motivo",
                Icons.edit_note_rounded,
              ),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TutorPalette.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    color: TutorPalette.primaryBlue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Puedes adjuntar comprobantes despues cuando el backend de archivos este conectado.",
                      style: TextStyle(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w600,
                        color: TutorPalette.textSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitJustification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TutorPalette.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  "Enviar justificacion",
                  style: TextStyle(fontWeight: FontWeight.w800),
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

  Future<void> _submitJustification() async {
    if (!_formKey.currentState!.validate() || _selectedIndex == null) {
      return;
    }

    // Estado optimista local: mantiene la interfaz util aunque el backend tutor
    // aun no tenga una coleccion propia de justificaciones.
    final updatedRecord = _records[_selectedIndex!].copyWith(
      reason: _reasonController.text.trim(),
      detail: _detailController.text.trim(),
      status: "En revision",
    );

    final sent = await TutorLiveDataService.submitAbsenceJustification(
      usuarioId: widget.userId,
      record: updatedRecord,
      reason: _reasonController.text.trim(),
      detail: _detailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _records[_selectedIndex!] = updatedRecord;
    });

    // Cuando haya persistencia real de justificaciones, aqui convendria tambien
    // recargar desde backend/Firebase para reflejar ids, archivos y estatus finales.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? "La justificacion se envio al backend actual para revision."
              : "La justificacion se guardo localmente mientras se completa la migracion.",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
