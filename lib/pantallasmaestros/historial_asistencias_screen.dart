import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/asistencia_service.dart';
import 'detalle_asistencia_screen.dart';

class HistorialAsistenciasScreen extends StatefulWidget {
  final Grupo grupo;

  const HistorialAsistenciasScreen({super.key, required this.grupo});

  @override
  State<HistorialAsistenciasScreen> createState() =>
      _HistorialAsistenciasScreenState();
}

class _HistorialAsistenciasScreenState
    extends State<HistorialAsistenciasScreen> {
  final Color primaryBlue = const Color(0xFF2D63ED);
  late Future<List<AsistenciaRegistro>> _future;

  @override
  void initState() {
    super.initState();
    _future = AsistenciaService.obtenerHistorialPorGrupo(widget.grupo.id);
  }

  Future<void> _recargar() async {
    setState(() {
      _future = AsistenciaService.obtenerHistorialPorGrupo(widget.grupo.id);
    });
  }

  String _fechaTexto(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          'Historial • ${widget.grupo.nombre}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<AsistenciaRegistro>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final registros = snapshot.data ?? [];

          if (registros.isEmpty) {
            return RefreshIndicator(
              onRefresh: _recargar,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      'Aún no hay asistencias guardadas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final item = registros[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalleAsistenciaScreen(registro: item),
                      ),
                    );
                    _recargar();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fechaTexto(item.fecha),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.materia,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniChip(
                              label: 'P: ${item.presentes}',
                              bg: const Color(0xFFDCFCE7),
                              fg: const Color(0xFF166534),
                            ),
                            _MiniChip(
                              label: 'A: ${item.ausentes}',
                              bg: const Color(0xFFFEE2E2),
                              fg: const Color(0xFF991B1B),
                            ),
                            _MiniChip(
                              label: 'R: ${item.retardos}',
                              bg: const Color(0xFFFFEDD5),
                              fg: const Color(0xFF9A3412),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Ver detalle',
                              style: TextStyle(
                                color: Color(0xFF2D63ED),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF2D63ED),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _MiniChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
