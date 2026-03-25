import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- MAGIA DE FIREBASE
import '../services/api_service.dart';

class DetalleActividadCalificacionScreen extends StatefulWidget {
  final Grupo grupo;
  final int actividadId;

  const DetalleActividadCalificacionScreen({
    super.key,
    required this.grupo,
    required this.actividadId,
  });

  @override
  State<DetalleActividadCalificacionScreen> createState() =>
      _DetalleActividadCalificacionScreenState();
}

class _DetalleActividadCalificacionScreenState
    extends State<DetalleActividadCalificacionScreen> {
  static const double _tableMinWidth = 1480;
  static const double _rowNumberWidth = 56;
  static const double _studentColumnWidth = 240;
  static const double _emailColumnWidth = 270;
  static const double _deliveryColumnWidth = 120;
  static const double _gradeColumnWidth = 150;
  static const double _quickScoreColumnWidth = 88;
  static const double _statusColumnWidth = 138;
  static const double _commentColumnWidth = 370;

  final TextEditingController _searchController = TextEditingController();
  final Map<int, TextEditingController> _gradeControllers = {};
  final Map<int, TextEditingController> _commentControllers = {};
  final Map<int, bool> _entregadoMap = {};
  final Map<int, String> _docIdsCalificaciones = {}; // Para saber qué documento de Firebase actualizar

  // Usamos un mapa para la info de la actividad en lugar del modelo viejo
  Map<String, dynamic>? _actividadInfo;
  List<ActividadAlumnoCaptura> _listaAlumnos = [];
  
  bool _loading = true;
  bool _saving = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim().toLowerCase());
    });
    _cargarDatosDesdeFirebase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _gradeControllers.values) { c.dispose(); }
    for (final c in _commentControllers.values) { c.dispose(); }
    super.dispose();
  }

  // ======================================================
  // 💾 LÓGICA FIREBASE (LEER)
  // ======================================================
  Future<void> _cargarDatosDesdeFirebase() async {
    setState(() => _loading = true);

    try {
      // 1. Cargar la info de la actividad
      final actSnapshot = await FirebaseFirestore.instance
          .collection('actividades')
          .where('id', isEqualTo: widget.actividadId)
          .limit(1)
          .get();

      if (actSnapshot.docs.isEmpty) throw Exception("No se encontró la actividad");
      final actData = actSnapshot.docs.first.data();

      // 2. Cargar los alumnos de este grupo
      final alumnosSnapshot = await FirebaseFirestore.instance
          .collection('alumnos')
          .where('grupoId', isEqualTo: widget.grupo.grupoIdReal)
          .get();

      // 3. Cargar las calificaciones YA guardadas para esta actividad
      final califSnapshot = await FirebaseFirestore.instance
          .collection('calificaciones')
          .where('actividadId', isEqualTo: widget.actividadId)
          .get();

      // Mapa rápido de calificaciones existentes: alumnoId -> data de Firebase
      final califMap = {
        for (var doc in califSnapshot.docs) 
          doc.data()['alumnoId'] as int: {'docId': doc.id, ...doc.data()}
      };

      if (!mounted) return;

      _gradeControllers.clear();
      _commentControllers.clear();
      _entregadoMap.clear();
      _docIdsCalificaciones.clear();
      _listaAlumnos.clear();

      for (var doc in alumnosSnapshot.docs) {
        final data = doc.data();
        final int alumnoId = data['id'] ?? doc.id.hashCode;
        final String nombre = data['nombre'] ?? 'Sin nombre';
        final String correo = data['correo'] ?? '';

        // Revisar si ya tiene calificación guardada
        final califExistente = califMap[alumnoId];
        final bool entregado = califExistente?['entregado'] ?? false;
        final double? calificacion = califExistente?['calificacion']?.toDouble();
        final String comentario = califExistente?['comentario'] ?? '';
        final bool revisado = califExistente != null;

        if (califExistente != null) {
          _docIdsCalificaciones[alumnoId] = califExistente['docId'] as String;
        }

        _entregadoMap[alumnoId] = entregado;
        _gradeControllers[alumnoId] = TextEditingController(text: _formatGrade(calificacion));
        _commentControllers[alumnoId] = TextEditingController(text: comentario);

        // Llenamos el modelo visual de la pantalla
        _listaAlumnos.add(ActividadAlumnoCaptura(
          id: 0, // <--- ¡AQUÍ ESTÁ LA MAGIA!
          alumnoId: alumnoId,
          nombre: nombre,
          correo: correo,
          entregado: entregado,
          calificacion: calificacion,
          comentario: comentario,
          estado: revisado ? (calificacion != null ? 'Calificado' : 'Entregado') : 'Pendiente',
          revisado: revisado,
        ));
      }
      // Ordenar alumnos
      _listaAlumnos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

      setState(() {
        _actividadInfo = actData;
        _loading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando actividad: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatGrade(double? value) {
    if (value == null) return '';
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  List<ActividadAlumnoCaptura> get _filteredAlumnos {
    if (_searchText.isEmpty) return _listaAlumnos;
    return _listaAlumnos.where((alumno) {
      return alumno.nombre.toLowerCase().contains(_searchText) ||
             alumno.correo.toLowerCase().contains(_searchText);
    }).toList();
  }

  void _marcarTodos(bool entregado) {
    setState(() {
      for (final alumno in _listaAlumnos) {
        _entregadoMap[alumno.alumnoId] = entregado;
        if (!entregado) _gradeControllers[alumno.alumnoId]?.clear();
      }
    });
  }

  // ======================================================
  // 💾 LÓGICA FIREBASE (GUARDAR)
  // ======================================================
  Future<void> _guardarCapturasFirebase() async {
    setState(() => _saving = true);
    final batch = FirebaseFirestore.instance.batch();
    final colRef = FirebaseFirestore.instance.collection('calificaciones');

    try {
      for (final alumno in _listaAlumnos) {
        final alumnoId = alumno.alumnoId;
        final entregado = _entregadoMap[alumnoId] ?? false;
        final rawGrade = _gradeControllers[alumnoId]?.text.trim() ?? '';
        final calificacion = rawGrade.isEmpty ? null : double.tryParse(rawGrade);

        if (rawGrade.isNotEmpty && (calificacion == null || calificacion < 0 || calificacion > 10)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Revisa la calificación de ${alumno.nombre}. (0 a 10)'), backgroundColor: Colors.red),
          );
          setState(() => _saving = false);
          return;
        }

        final dataToSave = {
          'actividadId': widget.actividadId,
          'grupoId': widget.grupo.grupoIdReal,
          'alumnoId': alumnoId,
          'entregado': entregado,
          'calificacion': entregado ? calificacion : null,
          'comentario': _commentControllers[alumnoId]?.text.trim() ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (_docIdsCalificaciones.containsKey(alumnoId)) {
          // Ya existe, lo actualizamos
          final docRef = colRef.doc(_docIdsCalificaciones[alumnoId]);
          batch.update(docRef, dataToSave);
        } else {
          // Es nuevo, lo creamos
          final docRef = colRef.doc();
          batch.set(docRef, {
            ...dataToSave,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Calificaciones guardadas en la nube! ☁️✅'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando en Firebase: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Funciones de UI
  void _actualizarEntrega(int alumnoId, bool entregado) {
    setState(() {
      _entregadoMap[alumnoId] = entregado;
      if (!entregado) _gradeControllers[alumnoId]?.clear();
    });
  }

  void _asignarCalificacionMaxima(int alumnoId) {
    _gradeControllers[alumnoId]?.text = '10';
  }

  String _rowStatusLabel(int alumnoId, ActividadAlumnoCaptura alumno) {
    final entregado = _entregadoMap[alumnoId] ?? false;
    if (!entregado) return 'No entrego';
    final gradeText = _gradeControllers[alumnoId]?.text.trim() ?? '';
    if (gradeText.isNotEmpty) return 'Calificado';
    if (alumno.revisado) return 'Revisado';
    return 'Entregado';
  }

  _StatusPalette _statusPalette(String label) {
    switch (label) {
      case 'Calificado': return const _StatusPalette(bg: Color(0xFFDBEAFE), fg: Color(0xFF1D4ED8));
      case 'Entregado':
      case 'Revisado': return const _StatusPalette(bg: Color(0xFFDCFCE7), fg: Color(0xFF166534));
      default: return const _StatusPalette(bg: Color(0xFFFEE2E2), fg: Color(0xFF991B1B));
    }
  }

  // ======================================================
  // 🎨 DISEÑO (Sin cambios para respetar el UI original)
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2D63ED);
    final isWideTable = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Capturar actividad', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _loading || _saving ? null : _guardarCapturasFirebase,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Guardando...' : 'Guardar actividad'),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : _actividadInfo == null
          ? const Center(child: Text('No se pudo cargar la actividad'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _actividadInfo!['titulo'] ?? 'Actividad sin título',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      if ((_actividadInfo!['descripcion'] ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_actividadInfo!['descripcion'], style: const TextStyle(color: Color(0xFF475569))),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _ActivityInfoChip(
                            icon: Icons.grade_rounded,
                            label: 'Vale ${(_actividadInfo!['valor'] ?? 10).toString()}',
                          ),
                          _ActivityInfoChip(
                            icon: Icons.assignment_turned_in_rounded,
                            label: (_actividadInfo!['cuentaParaFinal'] ?? true) ? 'Cuenta para final' : 'Solo seguimiento',
                          ),
                          if ((_actividadInfo!['fechaEntrega'] ?? '').isNotEmpty)
                            _ActivityInfoChip(
                              icon: Icons.event_rounded,
                              label: 'Entrega ${_actividadInfo!['fechaEntrega']}',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Buscar alumno',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _marcarTodos(true),
                            icon: const Icon(Icons.done_all_rounded),
                            label: const Text('Todos entregaron'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _marcarTodos(false),
                            icon: const Icon(Icons.block_rounded),
                            label: const Text('Todos no entregaron'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildStudentsBody(isWideTable)),
              ],
            ),
    );
  }

  Widget _buildStudentsBody(bool useTableLayout) {
    final alumnos = _filteredAlumnos;
    if (alumnos.isEmpty) return const Center(child: Text('No hay alumnos registrados en este grupo.'));
    return useTableLayout ? _buildSpreadsheetTable(alumnos) : _buildCardList(alumnos);
  }

  Widget _buildCardList(List<ActividadAlumnoCaptura> alumnos) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alumnos.length,
      itemBuilder: (context, index) {
        final alumno = alumnos[index];
        final alumnoId = alumno.alumnoId;
        final entregado = _entregadoMap[alumnoId] ?? false;
        final statusLabel = _rowStatusLabel(alumnoId, alumno);
        final statusPalette = _statusPalette(statusLabel);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alumno.nombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                        const SizedBox(height: 4),
                        Text('ID ${alumno.alumnoId} | ${alumno.correo}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Switch.adaptive(value: entregado, onChanged: (value) => _actualizarEntrega(alumnoId, value)),
                ],
              ),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _StatusChip(label: statusLabel, bg: statusPalette.bg, fg: statusPalette.fg),
                  if (alumno.revisado && statusLabel != 'Revisado')
                    const _StatusChip(label: 'Revisado', bg: Color(0xFFDBEAFE), fg: Color(0xFF1D4ED8)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gradeControllers[alumnoId],
                      enabled: entregado,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Calificación', hintText: '0 - 10', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(onPressed: entregado ? () => _asignarCalificacionMaxima(alumnoId) : null, child: const Text('10')),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentControllers[alumnoId],
                minLines: 2, maxLines: 3,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Comentario', hintText: 'Ej. Trabajo limpio...', border: OutlineInputBorder()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpreadsheetTable(List<ActividadAlumnoCaptura> alumnos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: _tableMinWidth,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  _buildSpreadsheetHeader(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: ListView.separated(
                        itemCount: alumnos.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (context, index) => _buildSpreadsheetRow(alumnos[index], index),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpreadsheetHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF4FF),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0)), left: BorderSide(color: Color(0xFFE2E8F0)), right: BorderSide(color: Color(0xFFE2E8F0)), bottom: BorderSide(color: Color(0xFFD7E3FF))),
      ),
      child: Row(
        children: [
          _headerCell('#', _rowNumberWidth, Alignment.centerLeft),
          _headerCell('Alumno', _studentColumnWidth, Alignment.centerLeft),
          _headerCell('Correo', _emailColumnWidth, Alignment.centerLeft),
          _headerCell('Entrega', _deliveryColumnWidth, Alignment.center),
          _headerCell('Calificación', _gradeColumnWidth, Alignment.center),
          _headerCell('Rápido', _quickScoreColumnWidth, Alignment.center),
          _headerCell('Estatus', _statusColumnWidth, Alignment.center),
          _headerCell('Comentario', _commentColumnWidth, Alignment.centerLeft),
        ],
      ),
    );
  }

  Widget _buildSpreadsheetRow(ActividadAlumnoCaptura alumno, int index) {
    final alumnoId = alumno.alumnoId;
    final entregado = _entregadoMap[alumnoId] ?? false;
    final statusLabel = _rowStatusLabel(alumnoId, alumno);
    final statusPalette = _statusPalette(statusLabel);

    return Container(
      color: index.isEven ? Colors.white : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tableCell(_rowNumberWidth, Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
          _tableCell(_studentColumnWidth, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(alumno.nombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)), const SizedBox(height: 4), Text('ID ${alumno.alumnoId}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)))] )),
          _tableCell(_emailColumnWidth, Text(alumno.correo, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
          _tableCell(_deliveryColumnWidth, Align(alignment: Alignment.center, child: Checkbox(value: entregado, onChanged: (value) => _actualizarEntrega(alumnoId, value ?? false)))),
          _tableCell(_gradeColumnWidth, TextField(controller: _gradeControllers[alumnoId], enabled: entregado, keyboardType: const TextInputType.numberWithOptions(decimal: true), textAlign: TextAlign.center, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: '0-10', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)))),
          _tableCell(_quickScoreColumnWidth, OutlinedButton(onPressed: entregado ? () => _asignarCalificacionMaxima(alumnoId) : null, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)), child: const Text('10'))),
          _tableCell(_statusColumnWidth, Align(alignment: Alignment.center, child: _StatusChip(label: statusLabel, bg: statusPalette.bg, fg: statusPalette.fg))),
          _tableCell(_commentColumnWidth, TextField(controller: _commentControllers[alumnoId], minLines: 1, maxLines: 2, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'Comentario del maestro', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)))),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width, Alignment alignment) => SizedBox(width: width, child: Align(alignment: alignment, child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)))));
  Widget _tableCell(double width, Widget child) => SizedBox(width: width, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: child));
}

class _StatusPalette { final Color bg; final Color fg; const _StatusPalette({required this.bg, required this.fg}); }

class _ActivityInfoChip extends StatelessWidget {
  final IconData icon; final String label; const _ActivityInfoChip({required this.icon, required this.label});
  @override Widget build(BuildContext context) { return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: const Color(0xFF2D63ED)), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))])); }
}

class _StatusChip extends StatelessWidget {
  final String label; final Color bg; final Color fg; const _StatusChip({required this.label, required this.bg, required this.fg});
  @override Widget build(BuildContext context) { return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800))); }
}