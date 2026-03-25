import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- LA NUBE
import '../services/api_service.dart';

class MensajesPadresScreen extends StatefulWidget {
  final int profesorId;

  const MensajesPadresScreen({super.key, required this.profesorId});

  @override
  State<MensajesPadresScreen> createState() => _MensajesPadresScreenState();
}

class _MensajesPadresScreenState extends State<MensajesPadresScreen> {
  final Color primaryBlue = const Color(0xFF2D63ED);
  final Color darkBlue = const Color(0xFF1E3A8A);
  final Color bgLight = const Color(0xFFF8FAFC);

  bool _loading = true;
  // Usaremos una lista de mapas para manejar los datos de Firebase de forma flexible
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _cargarDesdeFirebase();
  }

  // ======================================================
  // LÓGICA DE FIREBASE (Cargar Reportes)
  // ======================================================
  Future<void> _cargarDesdeFirebase() async {
    setState(() => _loading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reportes_tutor')
          .where('profesorId', isEqualTo: widget.profesorId)
          .orderBy('fecha', descending: true)
          .get();

      final data = snapshot.docs.map((doc) {
        final map = doc.data();
        map['id'] = doc.id; // Guardamos el ID del documento
        return map;
      }).toList();

      if (!mounted) return;

      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los mensajes: $error'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Mensajes de padres', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _cargarDesdeFirebase,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 18),
                  const Text(
                    'Justificaciones y reportes',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty) _buildEmptyState(),
                  if (_items.isNotEmpty) ..._items.map(_buildItemCard),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsRow() {
    final justificaciones = _items.where((item) => 
      (item['categoria'] ?? '').toString().toLowerCase() == 'justificacion de falta').length;
    final reportes = _items.length - justificaciones;

    return Row(
      children: [
        Expanded(child: _statCard(value: '${_items.length}', label: 'Total', icon: Icons.mail_outline_rounded, tint: primaryBlue)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(value: '$justificaciones', label: 'Justificaciones', icon: Icons.approval_rounded, tint: const Color(0xFFF59E0B))),
        const SizedBox(width: 12),
        Expanded(child: _statCard(value: '$reportes', label: 'Reportes', icon: Icons.chat_bubble_outline_rounded, tint: const Color(0xFF10B981))),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final categoria = (item['categoria'] ?? '').toString();
    final isJustificacion = categoria.toLowerCase() == 'justificacion de falta';
    final color = isJustificacion ? const Color(0xFFF59E0B) : primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
                child: Icon(isJustificacion ? Icons.approval_rounded : Icons.chat_bubble_outline_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['titulo'] ?? 'Sin título', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    Text('${item['tutorNombre'] ?? 'Tutor'} • ${item['alumnoNombre'] ?? 'Alumno'}', 
                      style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _badge(categoria, color),
            ],
          ),
          const SizedBox(height: 12),
          if ((item['materia'] ?? '').toString().trim().isNotEmpty) ...[
            _infoLine(Icons.menu_book_rounded, item['materia']),
            const SizedBox(height: 8),
          ],
          _infoLine(Icons.schedule_rounded, _formatearFecha(item['fecha'])),
          const SizedBox(height: 12),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Text(item['mensaje'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155), height: 1.45)),
          ),
          if (item['tieneAdjunto'] == true) ...[
            const SizedBox(height: 12),
            _buildAdjuntoWidget(item),
          ],
        ],
      ),
    );
  }

  Widget _buildAdjuntoWidget(Map<String, dynamic> item) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFBFDBFE))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.attach_file_rounded, color: Color(0xFF1D4ED8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['adjuntoNombre'] ?? 'Comprobante adjunto', style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
                if (item['adjuntoTamano'] != null) ...[
                  const SizedBox(height: 4),
                  Text(_formatFileSize(item['adjuntoTamano']), style: const TextStyle(fontSize: 12.3, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                ],
              ],
            ),
          ),
          if ((item['adjuntoUrl'] ?? '').toString().isNotEmpty)
            IconButton(
              onPressed: () => _copiarEnlaceAdjunto(item['adjuntoUrl']),
              icon: const Icon(Icons.link_rounded, color: Color(0xFF1D4ED8)),
              tooltip: 'Copiar enlace',
            ),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---

  String _formatearFecha(dynamic fecha) {
    if (fecha is Timestamp) {
      final dt = fecha.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return fecha.toString();
  }

  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryBlue, darkBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SEGUIMIENTO DE PADRES', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
            SizedBox(height: 12),
            Text('Aquí aparecen las justificaciones de faltas y los reportes que los padres envían sobre sus alumnos.', 
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.45)),
          ],
        ),
      ),
    );
  }

  Widget _statCard({required String value, required String label, required IconData icon, required Color tint}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: tint.withOpacity(0.10), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: tint)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12.5)),
          ])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: const Column(children: [
        Icon(Icons.mark_email_read_rounded, size: 44, color: Color(0xFF94A3B8)),
        SizedBox(height: 12),
        Text('Aun no hay mensajes de padres', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        SizedBox(height: 6),
        Text('Cuando un padre envíe una justificación o un reporte, aparecerá aquí.', 
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.45)),
      ]),
    );
  }

  Future<void> _copiarEnlaceAdjunto(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace del comprobante copiado')));
  }

  String _formatFileSize(dynamic bytes) {
    int b = (bytes is int) ? bytes : int.tryParse(bytes.toString()) ?? 0;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF64748B)),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
    ]);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
    );
  }
}