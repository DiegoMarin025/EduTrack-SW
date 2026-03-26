import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/asistencia_export_service.dart';
import '../services/asistencia_service.dart';

class DetalleAsistenciaScreen extends StatefulWidget {
  final AsistenciaRegistro registro;

  const DetalleAsistenciaScreen({super.key, required this.registro});

  @override
  State<DetalleAsistenciaScreen> createState() => _DetalleAsistenciaScreenState();
}

class _DetalleAsistenciaScreenState extends State<DetalleAsistenciaScreen> {
  final AsistenciaExportService _exportService = AsistenciaExportService();
  AsistenciaExportFormat? _exportando;

  String _fechaTexto(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  String _estadoTexto(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return 'Presente';
      case EstadoAsistencia.ausente:
        return 'Ausente';
      case EstadoAsistencia.retardo:
        return 'Retardo';
    }
  }

  Color _estadoBg(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return const Color(0xFFDCFCE7);
      case EstadoAsistencia.ausente:
        return const Color(0xFFFEE2E2);
      case EstadoAsistencia.retardo:
        return const Color(0xFFFFEDD5);
    }
  }

  Color _estadoFg(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return const Color(0xFF166534);
      case EstadoAsistencia.ausente:
        return const Color(0xFF991B1B);
      case EstadoAsistencia.retardo:
        return const Color(0xFF9A3412);
    }
  }

  Widget _buildStudentIdChip(int alumnoId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        'ID: $alumnoId',
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontWeight: FontWeight.w900,
          fontSize: 12.2,
        ),
      ),
    );
  }

  Future<void> _exportar(AsistenciaExportFormat format) async {
    setState(() => _exportando = format);

    try {
      final result = await _exportService.exportar(
        registro: widget.registro,
        format: format,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${format.label} listo: ${result.location}'),
          backgroundColor: const Color.fromARGB(255, 115, 145, 216),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exportando ${format.label}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exportando = null);
      }
    }
  }

  Widget _buildExportButton({
    required AsistenciaExportFormat format,
    required IconData icon,
  }) {
    final isLoading = _exportando == format;
    final isDisabled = _exportando != null;

    return SizedBox(
      width: 140,
      child: OutlinedButton.icon(
        onPressed: isDisabled ? null : () => _exportar(format),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(format.label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registro = widget.registro;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D63ED),
        foregroundColor: Colors.white,
        title: const Text(
          'Detalle de asistencia',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registro.grupoNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  registro.materia,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fecha: ${_fechaTexto(registro.fecha)}',
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildExportButton(
                      format: AsistenciaExportFormat.pdf,
                      icon: Icons.picture_as_pdf_rounded,
                    ),
                    _buildExportButton(
                      format: AsistenciaExportFormat.word,
                      icon: Icons.description_rounded,
                    ),
                    _buildExportButton(
                      format: AsistenciaExportFormat.excel,
                      icon: Icons.table_view_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: registro.detalles.length,
              itemBuilder: (context, index) {
                final item = registro.detalles[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombreAlumno,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStudentIdChip(item.alumnoId),
                      const SizedBox(height: 8),
                      Text(
                        item.correoAlumno,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _estadoBg(item.estado),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _estadoTexto(item.estado),
                          style: TextStyle(
                            color: _estadoFg(item.estado),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (item.nota.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            item.nota,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
