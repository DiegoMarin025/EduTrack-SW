import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- PODER NUBE
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
  State<ResumenFinalAlumnoScreen> createState() => _ResumenFinalAlumnoScreenState();
}

class _ResumenFinalAlumnoScreenState extends State<ResumenFinalAlumnoScreen> {
  final TextEditingController _finalController = TextEditingController();

  // Variables para guardar lo que calculemos
  Map<String, dynamic>? _alumnoData;
  List<Map<String, dynamic>> _actividadesCalculadas = [];
  double _calificacionSugerida = 0;
  double? _calificacionFinalGuardada;
  int _entregadas = 0;
  int _noEntregadas = 0;
  int _sinRegistrar = 0;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cargarTodoDesdeFirebase();
  }

  @override
  void dispose() {
    _finalController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodoDesdeFirebase() async {
    setState(() => _loading = true);

    try {
      // 1. Obtener info del Alumno
      final alumnoSnap = await FirebaseFirestore.instance
          .collection('alumnos')
          .where('id', isEqualTo: widget.alumnoId)
          .limit(1).get();
      
      if (alumnoSnap.docs.isNotEmpty) _alumnoData = alumnoSnap.docs.first.data();

      // 2. Obtener todas las Actividades de este grupo
      final actSnap = await FirebaseFirestore.instance
          .collection('actividades')
          .where('grupoIdReal', isEqualTo: widget.grupo.grupoIdReal)
          .get();

      // 3. Obtener todas las Calificaciones de este alumno en este grupo
      final califSnap = await FirebaseFirestore.instance
          .collection('calificaciones')
          .where('alumnoId', isEqualTo: widget.alumnoId)
          .where('grupoId', isEqualTo: widget.grupo.grupoIdReal)
          .get();

      // 4. Obtener si ya tiene una Calificación Final guardada
      final finalSnap = await FirebaseFirestore.instance
          .collection('calificaciones_finales')
          .doc('${widget.grupo.grupoIdReal}_${widget.alumnoId}')
          .get();

      if (finalSnap.exists) {
        _calificacionFinalGuardada = finalSnap.data()?['calificacion']?.toDouble();
      }

      // --- EMPIEZA LA MATEMÁTICA ---
      final califMap = {for (var doc in califSnap.docs) doc.data()['actividadId']: doc.data()};
      
      double puntosObtenidos = 0;
      double valorTotalActividades = 0;
      List<Map<String, dynamic>> listaVisual = [];

      for (var actDoc in actSnap.docs) {
        final act = actDoc.data();
        final int actId = act['id'];
        final double valorAct = (act['valor'] ?? 0).toDouble();
        final bool cuentaFinal = act['cuentaParaFinal'] ?? true;

        final califDoc = califMap[actId];
        final bool entregado = califDoc?['entregado'] ?? false;
        final double? nota = califDoc?['calificacion']?.toDouble();

        // Lógica de contadores
        if (califDoc == null) {
          _sinRegistrar++;
        } else if (entregado) {
          _entregadas++;
          if (cuentaFinal && nota != null) {
            // Regla de tres: si vale 2 puntos y sacó 10, son 2 puntos. Si sacó 5, es 1 punto.
            puntosObtenidos += (nota / 10) * valorAct;
          }
        } else {
          _noEntregadas++;
        }

        if (cuentaFinal) valorTotalActividades += valorAct;

        listaVisual.add({
          'titulo': act['titulo'] ?? 'Sin título',
          'valor': valorAct,
          'cuentaParaFinal': cuentaFinal,
          'fechaEntrega': act['fechaEntrega'] ?? '',
          'estado': califDoc == null ? 'Sin revisar' : (entregado ? (nota != null ? 'Calificado' : 'Entregado') : 'No entregado'),
          'entregado': entregado,
          'calificacion': nota,
          'comentario': califDoc?['comentario'] ?? '',
          'descripcion': act['descripcion'] ?? '',
        });
      }

      // Calcular sugerida (normalizada a base 10)
      if (valorTotalActividades > 0) {
        _calificacionSugerida = (puntosObtenidos / valorTotalActividades) * 10;
      }

      if (!mounted) return;

      setState(() {
        _actividadesCalculadas = listaVisual;
        _finalController.text = _formatGrade(_calificacionFinalGuardada ?? _calificacionSugerida);
        _loading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _guardarFinalFirebase() async {
    final val = double.tryParse(_finalController.text.trim());
    if (val == null || val < 0 || val > 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una nota válida (0-10)')));
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('calificaciones_finales')
          .doc('${widget.grupo.grupoIdReal}_${widget.alumnoId}')
          .set({
            'alumnoId': widget.alumnoId,
            'grupoId': widget.grupo.grupoIdReal,
            'calificacion': val,
            'fechaRegistro': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Calificación final guardada'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  String _formatGrade(double? value) {
    if (value == null) return '';
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2D63ED);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Resumen final del alumno', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                const Text('Resumen de actividades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                ..._actividadesCalculadas.map(_buildActividadCard),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_alumnoData?['nombre'] ?? 'Alumno', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(_alumnoData?['correo'] ?? '', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _MiniInfoPill(label: 'Sugerida ${_formatGrade(_calificacionSugerida)}'),
              _MiniInfoPill(label: 'Final ${_formatGrade(_calificacionFinalGuardada) == '' ? '--' : _formatGrade(_calificacionFinalGuardada)}'),
              _MiniInfoPill(label: 'Entregadas $_entregadas/${_actividadesCalculadas.length}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _finalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Calificación final', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(onPressed: () => _finalController.text = _formatGrade(_calificacionSugerida), child: const Text('Usar sugerida')),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _guardarFinalFirebase,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D63ED), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Guardando...' : 'Guardar calificación final'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActividadCard(Map<String, dynamic> act) {
    final Color bg = act['estado'] == 'Calificado' ? const Color(0xFFDBEAFE) : (act['estado'] == 'Entregado' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2));
    final Color fg = act['estado'] == 'Calificado' ? const Color(0xFF1D4ED8) : (act['estado'] == 'Entregado' ? const Color(0xFF166534) : const Color(0xFF991B1B));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(act['titulo'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(act['estado'], style: TextStyle(color: fg, fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 6),
          Text('Vale ${act['valor']} - ${act['cuentaParaFinal'] ? 'Cuenta para final' : 'Seguimiento'}', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(act['entregado'] ? 'Calificación: ${_formatGrade(act['calificacion'])}' : 'No entregado (0)', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}