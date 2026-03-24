import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/asistencia_service.dart';
import 'historial_asistencias_screen.dart';

class PasarListaScreen extends StatefulWidget {
  final Grupo grupo;
  final List<Alumno> alumnos;

  const PasarListaScreen({
    super.key,
    required this.grupo,
    required this.alumnos,
  });

  @override
  State<PasarListaScreen> createState() => _PasarListaScreenState();
}

class _PasarListaScreenState extends State<PasarListaScreen> {
  final Color primaryBlue = const Color(0xFF2D63ED);
  final Color bgLight = const Color(0xFFF8FAFC);

  late DateTime _fecha;
  late List<Alumno> _alumnos;
  final Map<int, EstadoAsistencia> _estadoPorAlumno = {};
  final Map<int, TextEditingController> _notaPorAlumno = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fecha = DateTime.now();
    _alumnos = [];
    _sincronizarAlumnos(widget.alumnos);
  }

  @override
  void dispose() {
    for (final c in _notaPorAlumno.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _fechaTexto() => DateFormat('dd/MM/yyyy').format(_fecha);

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked != null) {
      setState(() => _fecha = picked);
    }
  }

  void _marcarTodos(EstadoAsistencia estado) {
    setState(() {
      for (final a in _alumnos) {
        _estadoPorAlumno[a.id] = estado;
      }
    });
  }

  int _contar(EstadoAsistencia estado) {
    return _estadoPorAlumno.values.where((e) => e == estado).length;
  }

  Future<void> _editarNota(Alumno alumno) async {
    final controller = TextEditingController(
      text: _notaPorAlumno[alumno.id]?.text ?? '',
    );

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nota para ${alumno.nombre} | ID ${alumno.id}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escribe una nota',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: const Text('Guardar nota'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _notaPorAlumno[alumno.id]?.text = result;
      });
    }
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);

    try {
      final notas = <int, String>{};
      for (final a in _alumnos) {
        notas[a.id] = _notaPorAlumno[a.id]?.text.trim() ?? '';
      }

      await AsistenciaService.guardarAsistencia(
        grupo: widget.grupo,
        fecha: _fecha,
        alumnos: _alumnos,
        estados: _estadoPorAlumno,
        notas: notas,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HistorialAsistenciasScreen(grupo: widget.grupo),
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

  void _sincronizarAlumnos(List<Alumno> alumnos) {
    final ordered = List<Alumno>.from(
      alumnos,
    )..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    final validIds = ordered.map((alumno) => alumno.id).toSet();

    final idsToRemove = _notaPorAlumno.keys
        .where((id) => !validIds.contains(id))
        .toList();
    for (final id in idsToRemove) {
      _notaPorAlumno.remove(id)?.dispose();
      _estadoPorAlumno.remove(id);
    }

    for (final alumno in ordered) {
      _estadoPorAlumno.putIfAbsent(alumno.id, () => EstadoAsistencia.ausente);
      _notaPorAlumno.putIfAbsent(alumno.id, () => TextEditingController());
    }

    _alumnos = ordered;
  }

  Future<void> _mostrarDialogoAgregarAlumno() async {
    final nombreController = TextEditingController();
    final correoController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registrar alumno'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electronico',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final nombre = nombreController.text.trim();
                final correo = correoController.text.trim();

                if (nombre.isEmpty || correo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Completa nombre y correo del alumno'),
                    ),
                  );
                  return;
                }

                try {
                  final nuevoAlumno = await ApiService.crearAlumno(
                    nombre: nombre,
                    correo: correo,
                  );

                  await ApiService.agregarAlumnoAGrupo(
                    nuevoAlumno.id,
                    widget.grupo.grupoIdReal,
                  );

                  final alumnosActualizados =
                      await ApiService.getAlumnosRegistrados(widget.grupo);

                  if (!mounted) return;

                  setState(() {
                    _sincronizarAlumnos(alumnosActualizados);
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alumno registrado correctamente'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    } finally {
      nombreController.dispose();
      correoController.dispose();
    }
  }

  Color _colorEstado(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return const Color(0xFF16A34A);
      case EstadoAsistencia.ausente:
        return const Color(0xFFDC2626);
      case EstadoAsistencia.retardo:
        return const Color(0xFFEA580C);
    }
  }

  Widget _botonEstado(Alumno alumno, EstadoAsistencia estado, String texto) {
    final selected = _estadoPorAlumno[alumno.id] == estado;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _estadoPorAlumno[alumno.id] = estado;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _colorEstado(estado) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _colorEstado(estado) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            texto,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Color _estadoBg(EstadoAsistencia estado, bool selected) {
    if (!selected) return Colors.white;

    switch (estado) {
      case EstadoAsistencia.presente:
        return const Color(0xFFDCFCE7);
      case EstadoAsistencia.ausente:
        return const Color(0xFFFEE2E2);
      case EstadoAsistencia.retardo:
        return const Color(0xFFFFEDD5);
    }
  }

  Color _estadoBorder(EstadoAsistencia estado, bool selected) {
    if (!selected) return const Color(0xFFE2E8F0);

    switch (estado) {
      case EstadoAsistencia.presente:
        return const Color(0xFF22C55E);
      case EstadoAsistencia.ausente:
        return const Color(0xFFEF4444);
      case EstadoAsistencia.retardo:
        return const Color(0xFFF97316);
    }
  }

  Color _estadoText(EstadoAsistencia estado, bool selected) {
    if (!selected) return const Color(0xFF64748B);

    switch (estado) {
      case EstadoAsistencia.presente:
        return const Color(0xFF166534);
      case EstadoAsistencia.ausente:
        return const Color(0xFF991B1B);
      case EstadoAsistencia.retardo:
        return const Color(0xFF9A3412);
    }
  }

  Widget _buildEstadoCell({
    required int alumnoId,
    required EstadoAsistencia estadoCell,
    required String text,
  }) {
    final selected = _estadoPorAlumno[alumnoId] == estadoCell;

    return InkWell(
      onTap: () {
        setState(() {
          _estadoPorAlumno[alumnoId] = estadoCell;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _estadoBg(estadoCell, selected),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _estadoBorder(estadoCell, selected),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _estadoText(estadoCell, selected),
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double? width, Alignment? alignment}) {
    return Container(
      width: width,
      height: 48,
      alignment: alignment ?? Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildBodyCell({
    required Widget child,
    double? width,
    Alignment? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
  }) {
    return Container(
      width: width,
      height: 68,
      alignment: alignment ?? Alignment.centerLeft,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _buildHeader() {
    final presentes = _contar(EstadoAsistencia.presente);
    final ausentes = _contar(EstadoAsistencia.ausente);
    final retardos = _contar(EstadoAsistencia.retardo);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.grupo.materia,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _seleccionarFecha,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: primaryBlue),
                        const SizedBox(width: 10),
                        Text(
                          'Fecha: ${_fechaTexto()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'p') _marcarTodos(EstadoAsistencia.presente);
                  if (v == 'a') _marcarTodos(EstadoAsistencia.ausente);
                  if (v == 'r') _marcarTodos(EstadoAsistencia.retardo);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'p',
                    child: Text('Marcar todos: Presente'),
                  ),
                  PopupMenuItem(
                    value: 'a',
                    child: Text('Marcar todos: Ausente'),
                  ),
                  PopupMenuItem(
                    value: 'r',
                    child: Text('Marcar todos: Retardo'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    color: Colors.white,
                  ),
                  child: Icon(Icons.tune_rounded, color: primaryBlue),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Registrar alumno',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _mostrarDialogoAgregarAlumno,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: primaryBlue,
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
              _ResumenChip(
                label: 'Presentes: $presentes',
                bg: const Color(0xFFDCFCE7),
                fg: const Color(0xFF166534),
              ),
              _ResumenChip(
                label: 'Ausentes: $ausentes',
                bg: const Color(0xFFFEE2E2),
                fg: const Color(0xFF991B1B),
              ),
              _ResumenChip(
                label: 'Retardos: $retardos',
                bg: const Color(0xFFFFEDD5),
                fg: const Color(0xFF9A3412),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.badge_rounded, color: Color(0xFF1D4ED8), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Comparte el ID del alumno con su tutor para que pueda registrarse y vincular su cuenta.',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentIdChip(int alumnoId, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        'ID: $alumnoId',
        style: TextStyle(
          color: const Color(0xFF1D4ED8),
          fontWeight: FontWeight.w900,
          fontSize: compact ? 11.5 : 12.2,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Guardar lista',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVistaMovil() {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          'Pasar lista • ${widget.grupo.nombre}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Registrar alumno',
            onPressed: _mostrarDialogoAgregarAlumno,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HistorialAsistenciasScreen(grupo: widget.grupo),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _alumnos.isEmpty
                ? const Center(child: Text('No hay alumnos en este grupo'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alumnos.length,
                    itemBuilder: (context, index) {
                      final a = _alumnos[index];
                      final nota = _notaPorAlumno[a.id]?.text.trim() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: primaryBlue.withOpacity(
                                    0.10,
                                  ),
                                  foregroundColor: primaryBlue,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildStudentIdChip(a.id),
                                      const SizedBox(height: 6),
                                      Text(
                                        a.correo,
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _editarNota(a),
                                  icon: Icon(
                                    nota.isNotEmpty
                                        ? Icons.sticky_note_2_rounded
                                        : Icons.edit_note_rounded,
                                    color: nota.isNotEmpty
                                        ? const Color(0xFFEA580C)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _botonEstado(a, EstadoAsistencia.presente, 'P'),
                                const SizedBox(width: 8),
                                _botonEstado(a, EstadoAsistencia.ausente, 'A'),
                                const SizedBox(width: 8),
                                _botonEstado(a, EstadoAsistencia.retardo, 'R'),
                              ],
                            ),
                            if (nota.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFED7AA),
                                  ),
                                ),
                                child: Text(
                                  nota,
                                  style: const TextStyle(
                                    color: Color(0xFF9A3412),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
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

  Widget _buildVistaEscritorio() {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          'Pasar lista • ${widget.grupo.nombre}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Registrar alumno',
            onPressed: _mostrarDialogoAgregarAlumno,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HistorialAsistenciasScreen(grupo: widget.grupo),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _alumnos.isEmpty
                ? const Center(child: Text('No hay alumnos en este grupo'))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 1100,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _buildHeaderCell(
                                    '#',
                                    width: 55,
                                    alignment: Alignment.center,
                                  ),
                                  _buildHeaderCell('Alumno', width: 250),
                                  _buildHeaderCell(
                                    'ID alumno',
                                    width: 110,
                                    alignment: Alignment.center,
                                  ),
                                  _buildHeaderCell(
                                    'Presente',
                                    width: 120,
                                    alignment: Alignment.center,
                                  ),
                                  _buildHeaderCell(
                                    'Ausente',
                                    width: 120,
                                    alignment: Alignment.center,
                                  ),
                                  _buildHeaderCell(
                                    'Retardo',
                                    width: 120,
                                    alignment: Alignment.center,
                                  ),
                                  _buildHeaderCell('Nota', width: 315),
                                ],
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _alumnos.length,
                                  itemBuilder: (context, index) {
                                    final a = _alumnos[index];

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildBodyCell(
                                          width: 55,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                        _buildBodyCell(
                                          width: 250,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                a.nombre,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                a.correo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildBodyCell(
                                          width: 110,
                                          alignment: Alignment.center,
                                          child: _buildStudentIdChip(
                                            a.id,
                                            compact: true,
                                          ),
                                        ),
                                        _buildBodyCell(
                                          width: 120,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(8),
                                          child: _buildEstadoCell(
                                            alumnoId: a.id,
                                            estadoCell:
                                                EstadoAsistencia.presente,
                                            text: 'P',
                                          ),
                                        ),
                                        _buildBodyCell(
                                          width: 120,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(8),
                                          child: _buildEstadoCell(
                                            alumnoId: a.id,
                                            estadoCell:
                                                EstadoAsistencia.ausente,
                                            text: 'A',
                                          ),
                                        ),
                                        _buildBodyCell(
                                          width: 120,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(8),
                                          child: _buildEstadoCell(
                                            alumnoId: a.id,
                                            estadoCell:
                                                EstadoAsistencia.retardo,
                                            text: 'R',
                                          ),
                                        ),
                                        _buildBodyCell(
                                          width: 315,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                          child: TextField(
                                            controller: _notaPorAlumno[a.id],
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: 'Nota opcional',
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 700) {
      return _buildVistaMovil();
    }

    return _buildVistaEscritorio();
  }
}

class _ResumenChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _ResumenChip({required this.label, required this.bg, required this.fg});

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
