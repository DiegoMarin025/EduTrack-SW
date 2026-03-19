import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'mis_grupos_screen.dart';

class PlaneacionScreen extends StatefulWidget {
  const PlaneacionScreen({super.key});

  @override
  State<PlaneacionScreen> createState() => _PlaneacionScreenState();
}

class _PlaneacionScreenState extends State<PlaneacionScreen> {
  static const Color _primaryBlue = Color(0xFF2D63ED);
  static const Color _darkBlue = Color(0xFF1E3A8A);
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textSoft = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  final TextEditingController _temaController = TextEditingController();
  final TextEditingController _actividadController = TextEditingController();
  final List<_PlaneacionDraft> _planeaciones = [];

  List<Grupo> _materias = [];
  int? _selectedClaseId;
  int _profesorId = 0;
  String _nombreDocente = 'Profesor';
  DateTime _fechaSeleccionada = DateTime.now();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cargarContexto();
  }

  @override
  void dispose() {
    _temaController.dispose();
    _actividadController.dispose();
    super.dispose();
  }

  Future<void> _cargarContexto() async {
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final profesorId = prefs.getInt('saved_id') ?? 0;
      final nombreCompleto = prefs.getString('saved_name') ?? 'Profesor';

      List<Grupo> materias = [];
      if (profesorId != 0) {
        materias = await ApiService.getGrupos(profesorId: profesorId);
      }

      if (!mounted) return;

      setState(() {
        _profesorId = profesorId;
        _nombreDocente = _primerNombre(nombreCompleto);
        _materias = materias;
        _selectedClaseId = materias.isNotEmpty ? materias.first.id : null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron cargar las materias: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryBlue,
              onPrimary: Colors.white,
              onSurface: _textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() => _fechaSeleccionada = picked);
  }

  Future<void> _guardarPlaneacion() async {
    final tema = _temaController.text.trim();
    final actividad = _actividadController.text.trim();
    final materia = _materiaSeleccionada;

    if (tema.isEmpty || actividad.isEmpty || materia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa tema, actividad, fecha y materia antes de guardar.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 220));

    if (!mounted) return;

    setState(() {
      _planeaciones.insert(
        0,
        _PlaneacionDraft(
          tema: tema,
          actividad: actividad,
          fecha: _fechaSeleccionada,
          materia: materia.materia,
          grupo: materia.nombre,
        ),
      );
      _saving = false;
      _temaController.clear();
      _actividadController.clear();
      _fechaSeleccionada = DateTime.now();
      _selectedClaseId = _materias.isNotEmpty ? _materias.first.id : null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Planeacion agregada a la vista previa.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _limpiarFormulario() {
    setState(() {
      _temaController.clear();
      _actividadController.clear();
      _fechaSeleccionada = DateTime.now();
      _selectedClaseId = _materias.isNotEmpty ? _materias.first.id : null;
    });
  }

  void _eliminarPlaneacion(_PlaneacionDraft item) {
    setState(() => _planeaciones.remove(item));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Planeacion eliminada de la vista previa.')),
    );
  }

  Grupo? get _materiaSeleccionada {
    for (final materia in _materias) {
      if (materia.id == _selectedClaseId) {
        return materia;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 1100 : double.infinity,
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 28 : 20,
                          vertical: 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 16),
                            _buildHeroCard(isWide),
                            const SizedBox(height: 20),
                            _sectionTitle('Nueva planeacion'),
                            const SizedBox(height: 12),
                            _buildFormCard(isWide),
                            const SizedBox(height: 20),
                            _sectionTitle('Planeaciones capturadas'),
                            const SizedBox(height: 12),
                            _buildPlaneacionesSection(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _primaryBlue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.edit_calendar_rounded,
            color: _primaryBlue,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Planeacion docente',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Organiza tema, actividad, fecha y materia en un solo lugar para $_nombreDocente.',
                style: const TextStyle(
                  color: _textSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(bool isWide) {
    final stats = [
      _HeroStat(
        icon: Icons.menu_book_rounded,
        label: 'Materias cargadas',
        value: '${_materias.length}',
      ),
      _HeroStat(
        icon: Icons.event_note_rounded,
        label: 'Planeaciones',
        value: '${_planeaciones.length}',
      ),
      _HeroStat(
        icon: Icons.today_rounded,
        label: 'Fecha actual',
        value: _formatDate(_fechaSeleccionada),
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryBlue, _darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isWide
            ? Row(
                children: [
                  Expanded(child: _buildHeroText()),
                  const SizedBox(width: 18),
                  Flexible(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: stats
                          .map((item) => _buildHeroPill(item))
                          .toList(),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroText(),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: stats.map((item) => _buildHeroPill(item)).toList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'PLANEACION ACADEMICA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Captura cada clase con estructura clara y profesional.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Esta primera version te permite registrar el tema, la actividad, la fecha y la materia para tener organizada tu planeacion antes de conectarla al menu y a la base de datos.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPill(_HeroStat item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.8,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isWide) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: _primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registro de planeacion',
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Llena los campos obligatorios y agrega una planeacion a la vista previa.',
                      style: TextStyle(
                        color: _textSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _temaController,
            label: 'Tema',
            hint: 'Ej. Fracciones equivalentes',
            icon: Icons.lightbulb_outline_rounded,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _actividadController,
            label: 'Actividad',
            hint: 'Describe la dinamica, ejercicios o trabajo a realizar.',
            icon: Icons.task_alt_rounded,
            minLines: 4,
            maxLines: 6,
          ),
          const SizedBox(height: 14),
          if (isWide)
            Row(
              children: [
                Expanded(child: _buildDateField()),
                const SizedBox(width: 12),
                Expanded(child: _buildMateriaField()),
              ],
            )
          else
            Column(
              children: [
                _buildDateField(),
                const SizedBox(height: 12),
                _buildMateriaField(),
              ],
            ),
          if (_materias.isEmpty) ...[
            const SizedBox(height: 14),
            _buildNoMateriasNotice(),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _limpiarFormulario,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.cleaning_services_rounded),
                label: const Text(
                  'Limpiar',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ElevatedButton.icon(
                onPressed: (_saving || _materias.isEmpty)
                    ? null
                    : _guardarPlaneacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFBFDBFE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.add_task_rounded),
                label: Text(
                  _saving ? 'Guardando...' : 'Agregar planeacion',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _primaryBlue),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryBlue, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _seleccionarFecha,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha',
                    style: TextStyle(
                      color: _textSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(_fechaSeleccionada),
                    style: const TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: _textSoft),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriaField() {
    return DropdownButtonFormField<int>(
      value: _selectedClaseId,
      decoration: InputDecoration(
        labelText: 'Materia',
        prefixIcon: const Icon(Icons.menu_book_rounded, color: _primaryBlue),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryBlue, width: 1.4),
        ),
      ),
      items: _materias
          .map(
            (materia) => DropdownMenuItem(
              value: materia.id,
              child: Text('${materia.materia} - ${materia.nombre}'),
            ),
          )
          .toList(),
      onChanged: _materias.isEmpty
          ? null
          : (value) {
              setState(() => _selectedClaseId = value);
            },
    );
  }

  Widget _buildNoMateriasNotice() {
    final helperText = _profesorId == 0
        ? 'No se detecto la sesion del maestro. Inicia sesion otra vez y luego vuelve a esta pantalla.'
        : 'Puedes crearla en Mis Grupos y luego volver a esta pantalla.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: _primaryBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Primero necesitas al menos una materia para poder planear.',
                  style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            helperText,
            style: const TextStyle(
              color: _textSoft,
              fontWeight: FontWeight.w600,
              fontSize: 12.8,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MisGruposScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF93C5FD)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.class_rounded),
            label: const Text(
              'Ir a Mis Grupos',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaneacionesSection() {
    if (_planeaciones.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.library_add_check_rounded,
                color: _primaryBlue,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Todavia no has agregado planeaciones',
              style: TextStyle(
                color: _textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuando captures una, aparecera aqui como vista previa para revisar tema, actividad, fecha y materia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _planeaciones
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPlaneacionCard(item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPlaneacionCard(_PlaneacionDraft item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatDate(item.fecha),
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: () => _eliminarPlaneacion(item),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.tema,
            style: const TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _detailChip(icon: Icons.menu_book_rounded, text: item.materia),
              _detailChip(icon: Icons.groups_rounded, text: item.grupo),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Actividad',
            style: TextStyle(
              color: _textSoft,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.actividad,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _primaryBlue),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w900,
        color: Color(0xFF334155),
      ),
    );
  }

  String _primerNombre(String nombreCompleto) {
    final trimmed = nombreCompleto.trim();
    if (trimmed.isEmpty) return 'Profesor';
    return trimmed.split(' ').first;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    final month = months[(date.month - 1).clamp(0, 11)];
    return '${date.day} $month ${date.year}';
  }
}

class _HeroStat {
  final IconData icon;
  final String label;
  final String value;

  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _PlaneacionDraft {
  final String tema;
  final String actividad;
  final DateTime fecha;
  final String materia;
  final String grupo;

  const _PlaneacionDraft({
    required this.tema,
    required this.actividad,
    required this.fecha,
    required this.materia,
    required this.grupo,
  });
}
