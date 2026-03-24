import 'package:flutter/material.dart';

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

  ActividadClaseDetalle? _detalle;
  bool _loading = true;
  bool _saving = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim().toLowerCase());
    });
    _cargarDetalle();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _gradeControllers.values) {
      controller.dispose();
    }
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _loading = true);

    try {
      final detalle = await ApiService.getActividadClaseDetalle(
        widget.actividadId,
      );
      if (!mounted) return;

      for (final controller in _gradeControllers.values) {
        controller.dispose();
      }
      for (final controller in _commentControllers.values) {
        controller.dispose();
      }
      _gradeControllers.clear();
      _commentControllers.clear();
      _entregadoMap.clear();

      for (final alumno in detalle.alumnos) {
        _gradeControllers[alumno.alumnoId] = TextEditingController(
          text: _formatGrade(alumno.calificacion),
        );
        _commentControllers[alumno.alumnoId] = TextEditingController(
          text: alumno.comentario,
        );
        _entregadoMap[alumno.alumnoId] = alumno.entregado;
      }

      setState(() {
        _detalle = detalle;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando actividad: $e'),
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

  List<ActividadAlumnoCaptura> get _filteredAlumnos {
    final detalle = _detalle;
    if (detalle == null) return const [];
    if (_searchText.isEmpty) return detalle.alumnos;

    return detalle.alumnos.where((alumno) {
      return alumno.nombre.toLowerCase().contains(_searchText) ||
          alumno.correo.toLowerCase().contains(_searchText);
    }).toList();
  }

  void _marcarTodos(bool entregado) {
    final detalle = _detalle;
    if (detalle == null) return;

    setState(() {
      for (final alumno in detalle.alumnos) {
        _entregadoMap[alumno.alumnoId] = entregado;
        if (!entregado) {
          _gradeControllers[alumno.alumnoId]?.clear();
        }
      }
    });
  }

  Future<void> _guardarCapturas() async {
    final detalle = _detalle;
    if (detalle == null) return;

    final capturas = <ActividadAlumnoCaptura>[];

    for (final alumno in detalle.alumnos) {
      final alumnoId = alumno.alumnoId;
      final entregado = _entregadoMap[alumnoId] ?? false;
      final rawGrade = _gradeControllers[alumnoId]?.text.trim() ?? '';
      final calificacion = rawGrade.isEmpty ? null : double.tryParse(rawGrade);

      if (rawGrade.isNotEmpty && (calificacion == null || calificacion < 0 || calificacion > 10)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Revisa la calificacion de ${alumno.nombre}.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      capturas.add(
        alumno.copyWith(
          entregado: entregado,
          revisado: true,
          calificacion: calificacion,
          clearCalificacion: !entregado,
          comentario: _commentControllers[alumnoId]?.text.trim() ?? '',
          estado: !entregado
              ? 'No entregado'
              : (calificacion == null ? 'Entregado' : 'Calificado'),
        ),
      );
    }

    setState(() => _saving = true);

    try {
      await ApiService.guardarCapturasActividad(
        actividadId: detalle.id,
        capturas: capturas,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Actividad guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando actividad: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _actualizarEntrega(int alumnoId, bool entregado) {
    setState(() {
      _entregadoMap[alumnoId] = entregado;
      if (!entregado) {
        _gradeControllers[alumnoId]?.clear();
      }
    });
  }

  void _asignarCalificacionMaxima(int alumnoId) {
    _gradeControllers[alumnoId]?.text = '10';
  }

  String _rowStatusLabel(int alumnoId, ActividadAlumnoCaptura alumno) {
    final entregado = _entregadoMap[alumnoId] ?? false;
    if (!entregado) {
      return 'No entrego';
    }

    final gradeText = _gradeControllers[alumnoId]?.text.trim() ?? '';
    if (gradeText.isNotEmpty) {
      return 'Calificado';
    }

    if (alumno.revisado) {
      return 'Revisado';
    }

    return 'Entregado';
  }

  _StatusPalette _statusPalette(String label) {
    switch (label) {
      case 'Calificado':
        return const _StatusPalette(
          bg: Color(0xFFDBEAFE),
          fg: Color(0xFF1D4ED8),
        );
      case 'Entregado':
      case 'Revisado':
        return const _StatusPalette(
          bg: Color(0xFFDCFCE7),
          fg: Color(0xFF166534),
        );
      default:
        return const _StatusPalette(
          bg: Color(0xFFFEE2E2),
          fg: Color(0xFF991B1B),
        );
    }
  }

  Widget _buildStudentsBody(bool useTableLayout) {
    final alumnos = _filteredAlumnos;
    if (alumnos.isEmpty) {
      return const Center(child: Text('No hay alumnos para mostrar'));
    }

    return useTableLayout
        ? _buildSpreadsheetTable(alumnos)
        : _buildCardList(alumnos);
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alumno.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID ${alumno.alumnoId} | ${alumno.correo}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: entregado,
                    onChanged: (value) => _actualizarEntrega(alumnoId, value),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    label: statusLabel,
                    bg: statusPalette.bg,
                    fg: statusPalette.fg,
                  ),
                  if (alumno.revisado && statusLabel != 'Revisado')
                    const _StatusChip(
                      label: 'Revisado',
                      bg: Color(0xFFDBEAFE),
                      fg: Color(0xFF1D4ED8),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gradeControllers[alumnoId],
                      enabled: entregado,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Calificacion',
                        hintText: '0 - 10',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: entregado
                        ? () => _asignarCalificacionMaxima(alumnoId)
                        : null,
                    child: const Text('10'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentControllers[alumnoId],
                minLines: 2,
                maxLines: 3,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Comentario',
                  hintText:
                      'Ej. Trabajo limpio, necesita apoyo, no entrego evidencia.',
                  border: OutlineInputBorder(),
                ),
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListView.separated(
                        itemCount: alumnos.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFE2E8F0),
                        ),
                        itemBuilder: (context, index) {
                          final alumno = alumnos[index];
                          return _buildSpreadsheetRow(alumno, index);
                        },
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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
          left: BorderSide(color: Color(0xFFE2E8F0)),
          right: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFD7E3FF)),
        ),
      ),
      child: Row(
        children: [
          _headerCell('#', _rowNumberWidth, Alignment.centerLeft),
          _headerCell('Alumno', _studentColumnWidth, Alignment.centerLeft),
          _headerCell('Correo', _emailColumnWidth, Alignment.centerLeft),
          _headerCell('Entrega', _deliveryColumnWidth, Alignment.center),
          _headerCell('Calificacion', _gradeColumnWidth, Alignment.center),
          _headerCell('Rapido', _quickScoreColumnWidth, Alignment.center),
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
          _tableCell(
            _rowNumberWidth,
            Text(
              '${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          _tableCell(
            _studentColumnWidth,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alumno.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID ${alumno.alumnoId}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          _tableCell(
            _emailColumnWidth,
            Text(
              alumno.correo,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ),
          _tableCell(
            _deliveryColumnWidth,
            Align(
              alignment: Alignment.center,
              child: Checkbox(
                value: entregado,
                onChanged: (value) => _actualizarEntrega(
                  alumnoId,
                  value ?? false,
                ),
              ),
            ),
          ),
          _tableCell(
            _gradeColumnWidth,
            TextField(
              controller: _gradeControllers[alumnoId],
              enabled: entregado,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: '0-10',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
            ),
          ),
          _tableCell(
            _quickScoreColumnWidth,
            OutlinedButton(
              onPressed: entregado
                  ? () => _asignarCalificacionMaxima(alumnoId)
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
              child: const Text('10'),
            ),
          ),
          _tableCell(
            _statusColumnWidth,
            Align(
              alignment: Alignment.center,
              child: _StatusChip(
                label: statusLabel,
                bg: statusPalette.bg,
                fg: statusPalette.fg,
              ),
            ),
          ),
          _tableCell(
            _commentColumnWidth,
            TextField(
              controller: _commentControllers[alumnoId],
              minLines: 1,
              maxLines: 2,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Comentario del maestro',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width, Alignment alignment) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ),
    );
  }

  Widget _tableCell(double width, Widget child) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2D63ED);
    final detalle = _detalle;
    final isWideTable = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Capturar actividad',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _loading || _saving ? null : _guardarCapturas,
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
            label: Text(_saving ? 'Guardando...' : 'Guardar actividad'),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : detalle == null
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
                        detalle.titulo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (detalle.descripcion.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          detalle.descripcion,
                          style: const TextStyle(color: Color(0xFF475569)),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ActivityInfoChip(
                            icon: Icons.grade_rounded,
                            label: 'Vale ${detalle.valor.toStringAsFixed(detalle.valor % 1 == 0 ? 0 : 1)}',
                          ),
                          _ActivityInfoChip(
                            icon: Icons.assignment_turned_in_rounded,
                            label: detalle.cuentaParaFinal
                                ? 'Cuenta para final'
                                : 'Solo seguimiento',
                          ),
                          if (detalle.fechaEntrega.isNotEmpty)
                            _ActivityInfoChip(
                              icon: Icons.event_rounded,
                              label: 'Entrega ${detalle.fechaEntrega}',
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
                        spacing: 10,
                        runSpacing: 10,
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
                Expanded(
                  child: _buildStudentsBody(isWideTable),
                ),
              ],
            ),
    );
  }
}

class _StatusPalette {
  final Color bg;
  final Color fg;

  const _StatusPalette({
    required this.bg,
    required this.fg,
  });
}

class _ActivityInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActivityInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2D63ED)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _StatusChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

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
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
