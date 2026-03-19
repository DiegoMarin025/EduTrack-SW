import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/asistencia_service.dart';

class DetalleAsistenciaScreen extends StatelessWidget {
  final AsistenciaRegistro registro;

  const DetalleAsistenciaScreen({super.key, required this.registro});

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

  void _descargarPdf(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aquí después conectamos la exportación PDF'),
      ),
    );
  }

  void _descargarWord(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aquí después conectamos la exportación Word'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _descargarPdf(context),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text('PDF'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _descargarWord(context),
                        icon: const Icon(Icons.description_rounded),
                        label: const Text('Word'),
                      ),
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
