import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SubirCalificacionesScreen extends StatefulWidget {
  const SubirCalificacionesScreen({super.key});

  @override
  State<SubirCalificacionesScreen> createState() =>
      _SubirCalificacionesScreenState();
}

class _SubirCalificacionesScreenState extends State<SubirCalificacionesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, TextEditingController> _gradeControllers = {};
  final Map<int, bool> _savingRows = {};

  List<Grupo> _grupos = [];
  List<CalificacionesResumenAlumno> _rows = [];
  Grupo? _selectedGrupo;
  int _profesorId = 0;
  bool _loading = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _disposeRowControllers();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profesorId = prefs.getInt('saved_id') ?? 0;
    });

    if (_profesorId != 0) {
      await _cargarGrupos();
    }
  }

  Future<void> _cargarGrupos() async {
    try {
      final grupos = await ApiService.getGrupos(profesorId: _profesorId);
      if (!mounted) return;
      setState(() => _grupos = grupos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando grupos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchLibro(Grupo grupo) async {
    setState(() => _loading = true);
    _disposeRowControllers();

    try {
      List<CalificacionesResumenAlumno> rows = [];
      try {
        rows = await ApiService.getCalificacionesResumen(grupo.id);
      } catch (_) {
        rows = [];
      }

      final alumnos = await ApiService.getAlumnosRegistrados(grupo);
      if (!mounted) return;

      setState(() {
        _rows = _mergeRowsWithRegisteredStudents(rows, alumnos);
        for (final row in _rows) {
          _gradeControllers[row.id] = TextEditingController(
            text: _formatEditableGrade(row.calificacionFinal),
          );
          _savingRows[row.id] = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando libro de calificaciones: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _disposeRowControllers() {
    for (final controller in _gradeControllers.values) {
      controller.dispose();
    }
    _gradeControllers.clear();
    _savingRows.clear();
  }

  Future<void> _guardarCalificacionFinal(
    CalificacionesResumenAlumno alumno,
  ) async {
    final grupo = _selectedGrupo;
    if (grupo == null) return;

    final rawValue = _gradeControllers[alumno.id]?.text.trim() ?? '';
    if (rawValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una calificacion primero')),
      );
      return;
    }

    final calificacion = double.tryParse(rawValue);
    if (calificacion == null || calificacion < 0 || calificacion > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La calificacion debe estar entre 0 y 10')),
      );
      return;
    }

    setState(() => _savingRows[alumno.id] = true);

    try {
      await ApiService.guardarCalificacion(alumno.id, grupo.id, calificacion);
      if (!mounted) return;

      setState(() {
        final index = _rows.indexWhere((item) => item.id == alumno.id);
        if (index != -1) {
          _rows[index] = _rows[index].copyWith(calificacionFinal: calificacion);
        }
        _gradeControllers[alumno.id]?.text = _formatEditableGrade(calificacion);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calificacion final guardada para ${alumno.nombre}.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingRows[alumno.id] = false);
    }
  }

  void _llenarConDiez(CalificacionesResumenAlumno alumno) {
    _gradeControllers[alumno.id]?.text = '10';
  }

  Future<void> _abrirDetalleAlumno(CalificacionesResumenAlumno alumno) async {
    final grupo = _selectedGrupo;
    if (grupo == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlumnoActividadSheet(
        grupo: grupo,
        alumno: alumno,
        onChanged: () {
          _fetchLibro(grupo);
        },
      ),
    );
  }

  List<CalificacionesResumenAlumno> get _filteredRows {
    if (_searchText.isEmpty) return _rows;
    return _rows.where((row) {
      return row.nombre.toLowerCase().contains(_searchText) ||
          row.correo.toLowerCase().contains(_searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2D63ED);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Libro de calificaciones',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Captura final en tabla y abre cada alumno para registrar actividades o comentarios.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: _selectedGrupo?.id,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        hint: const Text('Selecciona una clase'),
                        items: _grupos.map((grupo) {
                          return DropdownMenuItem<int>(
                            value: grupo.id,
                            child: Text('${grupo.nombre} - ${grupo.materia}'),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          final grupo = _grupos.firstWhere(
                            (item) => item.id == id,
                          );
                          setState(() => _selectedGrupo = grupo);
                          _fetchLibro(grupo);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Buscar alumno',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.table_chart_rounded,
                    label: '${_rows.length} alumnos',
                  ),
                    _InfoPill(
                      icon: Icons.assignment_rounded,
                      label: _selectedGrupo == null
                          ? 'Sin clase seleccionada'
                          : '${_selectedGrupo!.nombre} - ${_selectedGrupo!.materia}',
                    ),
                  const _InfoPill(
                    icon: Icons.touch_app_rounded,
                    label: 'Toca el nombre para actividades y comentarios',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(color: primaryBlue),
                      )
                    : _selectedGrupo == null
                    ? const _EmptyState(
                        title: 'Selecciona una clase',
                        subtitle:
                            'Cuando elijas una materia aparecera el libro tipo tabla para capturar y editar calificaciones.',
                      )
                    : _filteredRows.isEmpty
                    ? const _EmptyState(
                        title: 'No hay alumnos para mostrar',
                        subtitle:
                            'Agrega alumnos al grupo o limpia la busqueda para revisar el listado completo.',
                      )
                    : _buildGradeTable(primaryBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeTable(Color primaryBlue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFF8FAFC),
              ),
              columnSpacing: 18,
              dataRowMinHeight: 86,
              dataRowMaxHeight: 86,
              columns: const [
                DataColumn(label: Text('Alumno')),
                DataColumn(label: Text('Final')),
                DataColumn(label: Text('Acciones')),
                DataColumn(label: Text('Actividades')),
                DataColumn(label: Text('Comentario reciente')),
              ],
              rows: _filteredRows.map((alumno) {
                final isSaving = _savingRows[alumno.id] ?? false;
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: InkWell(
                          onTap: () => _abrirDetalleAlumno(alumno),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                alumno.nombre,
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alumno.correo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 84,
                        child: TextField(
                          controller: _gradeControllers[alumno.id],
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0-10',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () => _llenarConDiez(alumno),
                            child: const Text('10'),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'Guardar final',
                            onPressed: isSaving
                                ? null
                                : () => _guardarCalificacionFinal(alumno),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                          ),
                          IconButton(
                            tooltip: 'Abrir detalle',
                            onPressed: () => _abrirDetalleAlumno(alumno),
                            icon: const Icon(Icons.sticky_note_2_rounded),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 110,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${alumno.totalActividades} registradas',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alumno.promedioActividades != null
                                  ? 'Prom. ${alumno.promedioActividades!.toStringAsFixed(1)}'
                                  : 'Sin promedio',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: Text(
                          alumno.ultimoComentario.isEmpty
                              ? 'Sin comentarios recientes'
                              : alumno.ultimoComentario,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  String _formatEditableGrade(double? value) {
    if (value == null) return '';
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  List<CalificacionesResumenAlumno> _mergeRowsWithRegisteredStudents(
    List<CalificacionesResumenAlumno> rows,
    List<Alumno> alumnos,
  ) {
    final byId = {
      for (final row in rows) row.id: row,
    };

    for (final alumno in alumnos) {
      byId.putIfAbsent(
        alumno.id,
        () => CalificacionesResumenAlumno(
          id: alumno.id,
          nombre: alumno.nombre,
          correo: alumno.correo,
          calificacionFinal: null,
          totalActividades: 0,
          promedioActividades: null,
          ultimoComentario: '',
        ),
      );
    }

    final merged = byId.values.toList();
    merged.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
    return merged;
  }
}

class _AlumnoActividadSheet extends StatefulWidget {
  final Grupo grupo;
  final CalificacionesResumenAlumno alumno;
  final VoidCallback onChanged;

  const _AlumnoActividadSheet({
    required this.grupo,
    required this.alumno,
    required this.onChanged,
  });

  @override
  State<_AlumnoActividadSheet> createState() => _AlumnoActividadSheetState();
}

class _AlumnoActividadSheetState extends State<_AlumnoActividadSheet> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _calificacionController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();

  List<ActividadCalificacion> _actividades = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cargarActividades();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _calificacionController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _cargarActividades() async {
    try {
      final actividades = await ApiService.getActividadesCalificacion(
        widget.alumno.id,
        widget.grupo.id,
      );
      if (!mounted) return;
      setState(() {
        _actividades = actividades;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando actividades: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _guardarActividad() async {
    final comentario = _comentarioController.text.trim();
    final titulo = _tituloController.text.trim();
    final gradeText = _calificacionController.text.trim();
    final calificacion = gradeText.isEmpty ? null : double.tryParse(gradeText);

    if (calificacion == null && gradeText.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La calificacion debe ser un numero')),
      );
      return;
    }

    if (calificacion != null && (calificacion < 0 || calificacion > 10)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La calificacion debe estar entre 0 y 10')),
      );
      return;
    }

    if (comentario.isEmpty && calificacion == null && titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega una actividad, una calificacion o un comentario'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ApiService.guardarActividadCalificacion(
        alumnoId: widget.alumno.id,
        grupoId: widget.grupo.id,
        titulo: titulo.isEmpty
            ? (comentario.isNotEmpty ? 'Comentario' : 'Actividad')
            : titulo,
        calificacion: calificacion,
        comentario: comentario,
      );

      _tituloController.clear();
      _calificacionController.clear();
      _comentarioController.clear();

      await _cargarActividades();
      widget.onChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Actividad o comentario guardado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2D63ED);

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.alumno.nombre,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.grupo.nombre} - ${widget.grupo.materia}',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.grade_rounded,
                      label: widget.alumno.calificacionFinal != null
                          ? 'Final ${widget.alumno.calificacionFinal!.toStringAsFixed(1)}'
                          : 'Sin final',
                    ),
                    _InfoPill(
                      icon: Icons.assignment_rounded,
                      label: '${widget.alumno.totalActividades} actividades previas',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nueva actividad o comentario',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Actividad',
                          hintText: 'Ej. Tarea 2, exposicion, seguimiento',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _calificacionController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Calificacion',
                                hintText: '0 - 10',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              _calificacionController.text = '10';
                            },
                            child: const Text('Poner 10'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _comentarioController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Reporte o comentario',
                          hintText:
                              'Ej. Participo muy bien, entregar evidencia pendiente, necesita reforzar tema 3.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _guardarActividad,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
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
                                _saving ? 'Guardando...' : 'Guardar',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Historial',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(color: primaryBlue),
                        )
                      : _actividades.isEmpty
                      ? const _EmptyState(
                          title: 'Sin movimientos todavia',
                          subtitle:
                              'Aqui apareceran las actividades, calificaciones extra y comentarios registrados para este alumno.',
                        )
                      : ListView.separated(
                          itemCount: _actividades.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final actividad = _actividades[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
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
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (actividad.calificacion != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDBEAFE),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            actividad.calificacion!
                                                .toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Color(0xFF1D4ED8),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDate(actividad.fecha),
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (actividad.comentario.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      actividad.comentario,
                                      style: const TextStyle(height: 1.4),
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
          ),
        ),
      ),
    );
  }

  String _formatDate(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year} - $hour:$minute';
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 44,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
