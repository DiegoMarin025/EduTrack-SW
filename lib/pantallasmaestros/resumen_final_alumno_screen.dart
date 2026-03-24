import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ResumenFinalAlumnoScreen extends StatefulWidget {
  final Grupo grupo;
  final int alumnoId;

  const ResumenFinalAlumnoScreen({
    super.key,
    required this.grupo,
    required this.alumnoId,
  });

  @override
  State<ResumenFinalAlumnoScreen> createState() =>
      _ResumenFinalAlumnoScreenState();
}

class _ResumenFinalAlumnoScreenState extends State<ResumenFinalAlumnoScreen> {
  final TextEditingController _finalController = TextEditingController();

  ResumenFinalAlumno? _resumen;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  @override
  void dispose() {
    _finalController.dispose();
    super.dispose();
  }

  Future<void> _cargarResumen() async {
    setState(() => _loading = true);

    try {
      final resumen = await ApiService.getResumenFinalAlumno(
        claseId: widget.grupo.id,
        alumnoId: widget.alumnoId,
      );
      if (!mounted) return;

      _finalController.text = _formatGrade(
        resumen.calificacionFinal ?? resumen.calificacionSugerida,
      );

      setState(() {
        _resumen = resumen;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando resumen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatGrade(double? value) {
    if (value == null) return '';
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  Color _statusBg(String estado) {
    switch (estado) {
      case 'Calificado':
        return const Color(0xFFDBEAFE);
      case 'Entregado':
        return const Color(0xFFDCFCE7);
      case 'No entregado':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusFg(String estado) {
    switch (estado) {
      case 'Calificado':
        return const Color(0xFF1D4ED8);
      case 'Entregado':
        return const Color(0xFF166534);
      case 'No entregado':
        return const Color(0xFF991B1B);
      default:
        return const Color(0xFF475569);
    }
  }

  Future<void> _guardarFinal() async {
    final resumen = _resumen;
    if (resumen == null) return;

    final rawValue = _finalController.text.trim();
    if (rawValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una calificacion final')),
      );
      return;
    }

    final calificacion = double.tryParse(rawValue);
    if (calificacion == null || calificacion < 0 || calificacion > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La calificacion final debe estar entre 0 y 10'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ApiService.guardarCalificacion(
        resumen.alumnoId,
        widget.grupo.id,
        calificacion,
      );
      if (!mounted) return;

      setState(() {
        _resumen = resumen.copyWith(calificacionFinal: calificacion);
        _finalController.text = _formatGrade(calificacion);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calificacion final guardada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando final: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumen = _resumen;
    final primaryBlue = const Color(0xFF2D63ED);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Resumen final del alumno',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : resumen == null
          ? const Center(child: Text('No se pudo cargar el resumen'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resumen.nombre,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resumen.correo,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniInfoPill(
                            label:
                                'Sugerida ${_formatGrade(resumen.calificacionSugerida).isEmpty ? '--' : _formatGrade(resumen.calificacionSugerida)}',
                          ),
                          _MiniInfoPill(
                            label:
                                'Final ${_formatGrade(resumen.calificacionFinal).isEmpty ? '--' : _formatGrade(resumen.calificacionFinal)}',
                          ),
                          _MiniInfoPill(
                            label:
                                'Entregadas ${resumen.entregadas}/${resumen.totalActividades}',
                          ),
                          _MiniInfoPill(
                            label: 'No entregadas ${resumen.noEntregadas}',
                          ),
                          _MiniInfoPill(
                            label: 'Sin revisar ${resumen.sinRegistrar}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _finalController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Calificacion final',
                                hintText: '0 - 10',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: resumen.calificacionSugerida == null
                                ? null
                                : () {
                                    _finalController.text = _formatGrade(
                                      resumen.calificacionSugerida,
                                    );
                                  },
                            child: const Text('Usar sugerida'),
                          ),
                        ],
                      ),
                      if (resumen.ultimoComentario.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            resumen.ultimoComentario,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _guardarFinal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _saving
                                ? 'Guardando...'
                                : 'Guardar calificacion final',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Resumen de actividades',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...resumen.actividades.map((actividad) {
                  final subtitleParts = <String>[
                    'Vale ${actividad.valor.toStringAsFixed(actividad.valor % 1 == 0 ? 0 : 1)}',
                    actividad.cuentaParaFinal ? 'Cuenta para final' : 'Seguimiento',
                    if (actividad.fechaEntrega.isNotEmpty)
                      'Entrega ${actividad.fechaEntrega}',
                  ];

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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                actividad.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _statusBg(actividad.estado),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                actividad.estado,
                                style: TextStyle(
                                  color: _statusFg(actividad.estado),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitleParts.join(' - '),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (actividad.descripcion.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            actividad.descripcion,
                            style: const TextStyle(color: Color(0xFF334155)),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          actividad.entregado
                              ? 'Calificacion: ${_formatGrade(actividad.calificacion).isEmpty ? '--' : _formatGrade(actividad.calificacion)}'
                              : 'Calificacion: 0 por no entrega',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (actividad.comentario.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              actividad.comentario,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  final String label;

  const _MiniInfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
