import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'detalle_actividad_calificacion_screen.dart';
import 'resumen_final_alumno_screen.dart';

class SubirCalificacionesScreen extends StatefulWidget {
  final int? initialGrupoId;

  const SubirCalificacionesScreen({super.key, this.initialGrupoId});

  @override
  State<SubirCalificacionesScreen> createState() =>
      _SubirCalificacionesScreenState();
}

class _SubirCalificacionesScreenState extends State<SubirCalificacionesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, TextEditingController> _finalControllers = {};
  final Map<int, bool> _savingFinalRows = {};

  List<Grupo> _grupos = [];
  List<ActividadClaseResumen> _actividades = [];
  List<ResumenFinalAlumno> _finales = [];
  Grupo? _selectedGrupo;
  int _profesorId = 0;
  bool _loading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim().toLowerCase());
    });
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _disposeFinalControllers();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    _profesorId = prefs.getInt('saved_id') ?? 0;

    if (_profesorId == 0) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    await _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    setState(() => _loading = true);

    try {
      final grupos = await ApiService.getGrupos(profesorId: _profesorId);
      if (!mounted) return;

      Grupo? grupoSeleccionado;
      final grupoActualId = _selectedGrupo?.id;

      if (grupoActualId != null) {
        for (final grupo in grupos) {
          if (grupo.id == grupoActualId) {
            grupoSeleccionado = grupo;
            break;
          }
        }
      }

      if (grupoSeleccionado == null && widget.initialGrupoId != null) {
        for (final grupo in grupos) {
          if (grupo.id == widget.initialGrupoId) {
            grupoSeleccionado = grupo;
            break;
          }
        }
      }

      grupoSeleccionado ??= grupos.isNotEmpty ? grupos.first : null;

      setState(() {
        _grupos = grupos;
        _selectedGrupo = grupoSeleccionado;
      });

      if (grupoSeleccionado == null) {
        _disposeFinalControllers();
        setState(() {
          _actividades = [];
          _finales = [];
          _loading = false;
        });
        return;
      }

      await _cargarContenidoGrupo(grupoSeleccionado);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando grupos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cargarContenidoGrupo(Grupo grupo) async {
    setState(() => _loading = true);

    List<ActividadClaseResumen> actividades = [];
    List<ResumenFinalAlumno> finales = [];
    Object? actividadesError;
    Object? finalesError;

    try {
      actividades = await ApiService.getActividadesClase(grupo.id);
    } catch (error) {
      actividadesError = error;
    }

    try {
      final resumen = await ApiService.getResumenFinalClase(grupo.id);
      finales = resumen.alumnos;
    } catch (error) {
      finalesError = error;
    }

    if (finales.isEmpty) {
      try {
        final alumnos = await ApiService.getAlumnosRegistrados(grupo);
        finales = alumnos.map(_buildResumenVacio).toList();
      } catch (error) {
        finalesError ??= error;
      }
    }

    if (!mounted) return;

    _replaceFinalControllers(finales);

    setState(() {
      _selectedGrupo = grupo;
      _actividades = actividades;
      _finales = finales;
      _loading = false;
    });

    if (actividadesError != null || finalesError != null) {
      final mensajes = <String>[
        if (actividadesError != null) 'Actividades: $actividadesError',
        if (finalesError != null) 'Finales: $finalesError',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajes.join(' | ')),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  ResumenFinalAlumno _buildResumenVacio(Alumno alumno) {
    return ResumenFinalAlumno(
      id: alumno.id,
      alumnoId: alumno.id,
      nombre: alumno.nombre,
      correo: alumno.correo,
      calificacionFinal: null,
      calificacionSugerida: null,
      promedioActividades: null,
      totalActividades: 0,
      entregadas: 0,
      noEntregadas: 0,
      sinRegistrar: 0,
      ultimoComentario: '',
      actividades: const [],
    );
  }

  void _replaceFinalControllers(List<ResumenFinalAlumno> finales) {
    _disposeFinalControllers();

    for (final alumno in finales) {
      _finalControllers[alumno.alumnoId] = TextEditingController(
        text: _formatGrade(
          alumno.calificacionFinal ?? alumno.calificacionSugerida,
        ),
      );
      _savingFinalRows[alumno.alumnoId] = false;
    }
  }

  void _disposeFinalControllers() {
    for (final controller in _finalControllers.values) {
      controller.dispose();
    }
    _finalControllers.clear();
    _savingFinalRows.clear();
  }

  List<ActividadClaseResumen> get _filteredActividades {
    if (_searchText.isEmpty) return _actividades;
    return _actividades.where((actividad) {
      return actividad.titulo.toLowerCase().contains(_searchText) ||
          actividad.descripcion.toLowerCase().contains(_searchText);
    }).toList();
  }

  List<ResumenFinalAlumno> get _filteredFinales {
    if (_searchText.isEmpty) return _finales;
    return _finales.where((alumno) {
      return alumno.nombre.toLowerCase().contains(_searchText) ||
          alumno.correo.toLowerCase().contains(_searchText);
    }).toList();
  }

  String _formatGrade(double? value) {
    if (value == null) return '';
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _formatValue(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _formatDate(String rawDate) {
    if (rawDate.trim().isEmpty) return 'Sin fecha';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }

  Future<void> _onGrupoSeleccionado(Grupo grupo) async {
    if (_selectedGrupo?.id == grupo.id && !_loading) return;
    await _cargarContenidoGrupo(grupo);
  }

  Future<void> _abrirCrearActividad() async {
    final grupo = _selectedGrupo;
    if (grupo == null) return;

    final draft = await showModalBottomSheet<_NuevaActividadInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CrearActividadSheet(grupo: grupo),
    );

    if (draft == null) return;

    setState(() => _loading = true);

    try {
      final actividadId = await ApiService.crearActividadClase(
        claseId: grupo.id,
        titulo: draft.titulo,
        descripcion: draft.descripcion,
        valor: draft.valor,
        fechaEntrega: draft.fechaEntregaIso,
        cuentaParaFinal: draft.cuentaParaFinal,
      );

      if (!mounted) return;

      await _cargarContenidoGrupo(grupo);
      if (!mounted) return;

      final updated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleActividadCalificacionScreen(
            grupo: grupo,
            actividadId: actividadId,
          ),
        ),
      );

      if (updated == true && mounted) {
        await _cargarContenidoGrupo(grupo);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creando actividad: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirDetalleActividad(ActividadClaseResumen actividad) async {
    final grupo = _selectedGrupo;
    if (grupo == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleActividadCalificacionScreen(
          grupo: grupo,
          actividadId: actividad.id,
        ),
      ),
    );

    if (updated == true && mounted) {
      await _cargarContenidoGrupo(grupo);
    }
  }

  Future<void> _abrirResumenAlumno(ResumenFinalAlumno alumno) async {
    final grupo = _selectedGrupo;
    if (grupo == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ResumenFinalAlumnoScreen(
          grupo: grupo,
          alumnoId: alumno.alumnoId,
        ),
      ),
    );

    if (updated == true && mounted) {
      await _cargarContenidoGrupo(grupo);
    }
  }

  void _usarSugerida(ResumenFinalAlumno alumno) {
    final sugerida = alumno.calificacionSugerida;
    if (sugerida == null) return;
    _finalControllers[alumno.alumnoId]?.text = _formatGrade(sugerida);
  }

  Future<void> _guardarCalificacionFinal(ResumenFinalAlumno alumno) async {
    final grupo = _selectedGrupo;
    if (grupo == null) return;

    final controller = _finalControllers[alumno.alumnoId];
    final rawValue = controller?.text.trim() ?? '';

    if (rawValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingresa una calificacion para ${alumno.nombre}.'),
        ),
      );
      return;
    }

    final calificacion = double.tryParse(rawValue);
    if (calificacion == null || calificacion < 0 || calificacion > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La calificacion de ${alumno.nombre} debe estar entre 0 y 10.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _savingFinalRows[alumno.alumnoId] = true);

    try {
      await ApiService.guardarCalificacion(
        alumno.alumnoId,
        grupo.id,
        calificacion,
      );
      if (!mounted) return;

      setState(() {
        final index = _finales.indexWhere(
          (item) => item.alumnoId == alumno.alumnoId,
        );
        if (index != -1) {
          _finales[index] = _finales[index].copyWith(
            calificacionFinal: calificacion,
          );
        }
        controller?.text = _formatGrade(calificacion);
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
          content: Text('Error guardando final: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingFinalRows[alumno.alumnoId] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2D63ED);
    final grupo = _selectedGrupo;
    final alumnosConFinal = _finales
        .where((alumno) => alumno.calificacionFinal != null)
        .length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calificaciones',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Crea actividades para tu grupo, captura entregas y guarda la calificacion final de cada alumno.',
                  style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 16),
                _FilterPanel(
                  grupos: _grupos,
                  selectedGrupo: grupo,
                  searchController: _searchController,
                  loading: _loading,
                  onGrupoChanged: _onGrupoSeleccionado,
                  onRefresh: grupo == null
                      ? null
                      : () => _cargarContenidoGrupo(grupo),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryChip(
                      icon: Icons.groups_rounded,
                      label: '${_finales.length} alumnos',
                    ),
                    _SummaryChip(
                      icon: Icons.assignment_rounded,
                      label: '${_actividades.length} actividades',
                    ),
                    _SummaryChip(
                      icon: Icons.grade_rounded,
                      label: '$alumnosConFinal finales guardadas',
                    ),
                    if (grupo != null)
                      _SummaryChip(
                        icon: Icons.menu_book_rounded,
                        label: '${grupo.nombre} - ${grupo.materia}',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: primaryBlue,
                          unselectedLabelColor: const Color(0xFF64748B),
                          indicatorColor: primaryBlue,
                          tabs: const [
                            Tab(text: 'Actividades'),
                            Tab(text: 'Finales'),
                          ],
                        ),
                        SizedBox(
                          height: 1,
                          child: Container(color: const Color(0xFFE2E8F0)),
                        ),
                        Expanded(
                          child: _loading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: primaryBlue,
                                  ),
                                )
                              : grupo == null
                              ? const _EmptyState(
                                  icon: Icons.class_rounded,
                                  title:
                                      'Todavia no tienes clases disponibles',
                                  subtitle:
                                      'Cuando tengas un grupo asignado podras crear actividades y cerrar calificaciones finales.',
                                )
                              : TabBarView(
                                  children: [
                                    _buildActividadesTab(primaryBlue),
                                    _buildFinalesTab(primaryBlue),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActividadesTab(Color primaryBlue) {
    final actividades = _filteredActividades;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 700;
                final info = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Nueva actividad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Crea una actividad para todo el grupo y enseguida captura si cada alumno entrego y cuanto saco.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                );

                final button = ElevatedButton.icon(
                  onPressed: _selectedGrupo == null ? null : _abrirCrearActividad,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Crear actividad'),
                );

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      info,
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: button),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 16),
                    button,
                  ],
                );
              },
            ),
          ),
        ),
        Expanded(
          child: actividades.isEmpty
              ? _EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'Todavia no hay actividades',
                  subtitle:
                      'Empieza creando la primera actividad del grupo para capturar entregas y calificaciones.',
                  actionLabel: 'Crear actividad',
                  onAction: _selectedGrupo == null ? null : _abrirCrearActividad,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: actividades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final actividad = actividades[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _abrirDetalleActividad(actividad),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                                        actividad.titulo,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      if (actividad.descripcion
                                          .trim()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          actividad.descripcion,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _abrirDetalleActividad(
                                    actividad,
                                  ),
                                  icon: const Icon(Icons.edit_note_rounded),
                                  label: const Text('Capturar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MiniChip(
                                  label: 'Vale ${_formatValue(actividad.valor)}',
                                ),
                                _MiniChip(
                                  label:
                                      'Entrega ${_formatDate(actividad.fechaEntrega)}',
                                ),
                                _MiniChip(
                                  label: actividad.cuentaParaFinal
                                      ? 'Cuenta para final'
                                      : 'Solo seguimiento',
                                ),
                                _MiniChip(
                                  label: '${actividad.entregados} entregados',
                                ),
                                _MiniChip(
                                  label:
                                      '${actividad.noEntregados} no entregados',
                                ),
                                _MiniChip(
                                  label: '${actividad.capturas} capturas',
                                ),
                                if (actividad.promedio != null)
                                  _MiniChip(
                                    label:
                                        'Promedio ${_formatGrade(actividad.promedio)}',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFinalesTab(Color primaryBlue) {
    final finales = _filteredFinales;

    if (finales.isEmpty) {
      return const _EmptyState(
        icon: Icons.groups_rounded,
        title: 'Aun no hay alumnos en este grupo',
        subtitle:
            'Cuando el grupo tenga alumnos registrados aqui podras ver su promedio sugerido y guardar su calificacion final.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: finales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final alumno = finales[index];
        final controller = _finalControllers[alumno.alumnoId]!;
        final saving = _savingFinalRows[alumno.alumnoId] ?? false;

        return Container(
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
                alumno.nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                alumno.correo,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniChip(
                    label:
                        'Sugerida ${_formatGrade(alumno.calificacionSugerida).isEmpty ? '--' : _formatGrade(alumno.calificacionSugerida)}',
                  ),
                  _MiniChip(
                    label:
                        'Final ${_formatGrade(alumno.calificacionFinal).isEmpty ? '--' : _formatGrade(alumno.calificacionFinal)}',
                  ),
                  _MiniChip(
                    label:
                        'Entregadas ${alumno.entregadas}/${alumno.totalActividades}',
                  ),
                  _MiniChip(label: 'No entregadas ${alumno.noEntregadas}'),
                  _MiniChip(label: 'Sin revisar ${alumno.sinRegistrar}'),
                ],
              ),
              if (alumno.ultimoComentario.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    alumno.ultimoComentario,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 880;

                  final input = SizedBox(
                    width: stacked ? double.infinity : 180,
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Calificacion final',
                        hintText: '0 - 10',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  );

                  final actions = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: alumno.calificacionSugerida == null
                            ? null
                            : () => _usarSugerida(alumno),
                        child: const Text('Usar sugerida'),
                      ),
                      ElevatedButton.icon(
                        onPressed: saving
                            ? null
                            : () => _guardarCalificacionFinal(alumno),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(saving ? 'Guardando...' : 'Guardar final'),
                      ),
                      TextButton.icon(
                        onPressed: () => _abrirResumenAlumno(alumno),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Ver resumen'),
                      ),
                    ],
                  );

                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        input,
                        const SizedBox(height: 12),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      input,
                      const SizedBox(width: 12),
                      Expanded(child: actions),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final List<Grupo> grupos;
  final Grupo? selectedGrupo;
  final TextEditingController searchController;
  final bool loading;
  final ValueChanged<Grupo> onGrupoChanged;
  final VoidCallback? onRefresh;

  const _FilterPanel({
    required this.grupos,
    required this.selectedGrupo,
    required this.searchController,
    required this.loading,
    required this.onGrupoChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 880;

        final dropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonFormField<int>(
            value: selectedGrupo?.id,
            decoration: const InputDecoration(
              labelText: 'Clase',
              border: InputBorder.none,
            ),
            hint: const Text('Selecciona una clase'),
            items: grupos.map((grupo) {
              return DropdownMenuItem<int>(
                value: grupo.id,
                child: Text('${grupo.nombre} - ${grupo.materia}'),
              );
            }).toList(),
            onChanged: loading
                ? null
                : (id) {
                    if (id == null) return;
                    for (final grupo in grupos) {
                      if (grupo.id == id) {
                        onGrupoChanged(grupo);
                        break;
                      }
                    }
                  },
          ),
        );

        final search = TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Buscar actividad o alumno',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: searchController.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2D63ED)),
            ),
          ),
        );

        final refresh = SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualizar'),
          ),
        );

        if (stacked) {
          return Column(
            children: [
              dropdown,
              const SizedBox(height: 12),
              search,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: refresh),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: dropdown),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: search),
            const SizedBox(width: 12),
            refresh,
          ],
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

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
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: const Color(0xFF94A3B8)),
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D63ED),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NuevaActividadInput {
  final String titulo;
  final String descripcion;
  final double valor;
  final String? fechaEntregaIso;
  final bool cuentaParaFinal;

  const _NuevaActividadInput({
    required this.titulo,
    required this.descripcion,
    required this.valor,
    required this.fechaEntregaIso,
    required this.cuentaParaFinal,
  });
}

class _CrearActividadSheet extends StatefulWidget {
  final Grupo grupo;

  const _CrearActividadSheet({required this.grupo});

  @override
  State<_CrearActividadSheet> createState() => _CrearActividadSheetState();
}

class _CrearActividadSheetState extends State<_CrearActividadSheet> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  DateTime? _fechaEntrega;
  bool _cuentaParaFinal = true;
  bool _saving = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  String _displayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() => _fechaEntrega = picked);
    }
  }

  void _submit() {
    final titulo = _tituloController.text.trim();
    final descripcion = _descripcionController.text.trim();
    final valor = double.tryParse(_valorController.text.trim());

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre de la actividad.')),
      );
      return;
    }

    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Indica cuanto vale la actividad con un numero mayor a cero.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    Navigator.pop(
      context,
      _NuevaActividadInput(
        titulo: titulo,
        descripcion: descripcion,
        valor: valor,
        fechaEntregaIso:
            _fechaEntrega == null ? null : _isoDate(_fechaEntrega!),
        cuentaParaFinal: _cuentaParaFinal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2D63ED);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Crear actividad',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Grupo ${widget.grupo.nombre} - ${widget.grupo.materia}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la actividad',
                    hintText: 'Ej. Tarea 3, lectura, examen corto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descripcionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion',
                    hintText: 'Explica que hicieron o que se esperaba entregar.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _valorController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cuanto vale',
                    hintText: 'Ej. 10',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            color: Color(0xFF2D63ED),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _fechaEntrega == null
                                  ? 'Sin fecha de entrega'
                                  : 'Entrega ${_displayDate(_fechaEntrega!)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _pickDate,
                            child: Text(
                              _fechaEntrega == null ? 'Elegir' : 'Cambiar',
                            ),
                          ),
                        ],
                      ),
                      if (_fechaEntrega != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() => _fechaEntrega = null);
                            },
                            child: const Text('Quitar fecha'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _cuentaParaFinal,
                  onChanged: (value) {
                    setState(() => _cuentaParaFinal = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Contar para la calificacion final',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Si lo desactivas, la actividad solo sirve como seguimiento.',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Continuar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
