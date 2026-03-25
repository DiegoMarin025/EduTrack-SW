import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../services/api_service.dart';

class PlaneacionScreen extends StatefulWidget {
  const PlaneacionScreen({super.key});

  @override
  State<PlaneacionScreen> createState() => _PlaneacionScreenState();
}

class _PlaneacionScreenState extends State<PlaneacionScreen> {
  // --- TUS COLORES ORIGINALES ---
  static const Color _primaryBlue = Color(0xFF2D63ED);
  static const Color _darkBlue = Color(0xFF1E3A8A);
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textSoft = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  final TextEditingController _temaController = TextEditingController();
  final TextEditingController _actividadController = TextEditingController();
  
  List<Map<String, dynamic>> _planeaciones = [];
  List<Grupo> _materias = [];
  int? _selectedClaseId;
  String _profesorId = ""; // 🟢 Cambiado a String para que coincida con tu UID de Firebase
  String _nombreDocente = 'Profesor';
  DateTime _fechaSeleccionada = DateTime.now();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // 🟢 Escuchamos los cambios para habilitar el botón
    _temaController.addListener(() => setState(() {})); 
    _cargarContextoFirebase();
  }

  @override
  void dispose() {
    _temaController.dispose();
    _actividadController.dispose();
    super.dispose();
  }

  // ======================================================
  // 💾 LÓGICA DE FIREBASE (El motor que sí sirve)
  // ======================================================
  Future<void> _cargarContextoFirebase() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      // 🟢 Obtenemos tu UID (el que vimos en la foto de Firebase)
      final profUid = prefs.getString('saved_uid') ?? "qcT8HBPWnNQpRMGl3O32vudf1X2";
      final nombreCompleto = prefs.getString('saved_name') ?? 'Profesor';

      // 1. Cargar tus Materias (Colección 'grupos')
      final gruposSnapshot = await FirebaseFirestore.instance
          .collection('grupos')
          .where('profesorId', isEqualTo: profUid)
          .get();

      final materias = gruposSnapshot.docs.map((doc) => Grupo(
        id: doc.data()['id'] ?? doc.id.hashCode,
        nombre: doc.data()['nombre'] ?? '',
        materia: doc.data()['materia'] ?? '',
        grupoIdReal: doc.data()['grupoIdReal'] ?? 0,
      )).toList();

      // 2. Cargar tus Planeaciones guardadas
      final planeacionesSnapshot = await FirebaseFirestore.instance
          .collection('planeaciones')
          .where('profesorId', isEqualTo: profUid)
          .orderBy('createdAt', descending: true)
          .get();

      final planeaciones = planeacionesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _profesorId = profUid;
          _nombreDocente = nombreCompleto.split(' ').first;
          _materias = materias;
          _planeaciones = planeaciones;
          _selectedClaseId = materias.isNotEmpty ? materias.first.id : null;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guardarPlaneacionFirebase() async {
    final tema = _temaController.text.trim();
    final actividad = _actividadController.text.trim();
    final materiaObj = _materiaSeleccionada;

    if (tema.isEmpty || materiaObj == null) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('planeaciones').add({
        'tema': tema,
        'actividad': actividad,
        'fecha': Timestamp.fromDate(_fechaSeleccionada),
        'materia': materiaObj.materia,
        'grupo': materiaObj.nombre,
        'grupoIdReal': materiaObj.grupoIdReal,
        'profesorId': _profesorId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _temaController.clear();
      _actividadController.clear();
      await _cargarContextoFirebase(); // Recargamos la lista automáticamente

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Planeación guardada! ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // --- MÉTODOS DE UI ---

  Grupo? get _materiaSeleccionada {
    for (final m in _materias) { if (m.id == _selectedClaseId) return m; }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 El botón se activa si hay tema y materia seleccionada
    bool canSave = _temaController.text.isNotEmpty && _selectedClaseId != null && !_saving;

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildHeroCard(),
                    const SizedBox(height: 20),
                    const Text('Nueva planeación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    // FORMULARIO PRO
                    _buildFormCard(canSave),
                    
                    const SizedBox(height: 24),
                    const Text('Planeaciones capturadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildPlaneacionesSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFormCard(bool canSave) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildTextField(controller: _temaController, label: 'Tema', hint: 'Ej. Fracciones', icon: Icons.lightbulb_outline),
          const SizedBox(height: 14),
          _buildTextField(controller: _actividadController, label: 'Actividad', hint: 'Descripción...', icon: Icons.task_alt, maxLines: 3),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildDateField()),
              const SizedBox(width: 12),
              Expanded(child: _buildMateriaField()),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: canSave ? _guardarPlaneacionFirebase : null,
              icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_task),
              label: const Text('Agregar planeación', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: canSave ? _primaryBlue : Colors.grey.shade200,
                foregroundColor: canSave ? Colors.white : Colors.grey.shade500,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PIEZAS DE DISEÑO RESTAURADAS ---

  Widget _buildHeader() {
    return Row(children: [
      const Icon(Icons.edit_calendar_rounded, color: _primaryBlue, size: 30),
      const SizedBox(width: 12),
      Text('Hola, $_nombreDocente', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
    ]);
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primaryBlue, _darkBlue]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLANEACIÓN ACADÉMICA', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Captura cada clase con estructura clara.', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPlaneacionesSection() {
    if (_planeaciones.isEmpty) return const Center(child: Text('No hay planeaciones aún.'));
    return Column(
      children: _planeaciones.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          title: Text(item['tema'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${item['materia']} - ${item['grupo']}"),
          trailing: const Icon(Icons.chevron_right),
        ),
      )).toList(),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final pick = await showDatePicker(context: context, initialDate: _fechaSeleccionada, firstDate: DateTime(2024), lastDate: DateTime(2030));
        if (pick != null) setState(() => _fechaSeleccionada = pick);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [const Icon(Icons.calendar_today, size: 18, color: _primaryBlue), const SizedBox(width: 8), Text("${_fechaSeleccionada.day}/${_fechaSeleccionada.month}")]),
      ),
    );
  }

  Widget _buildMateriaField() {
    return DropdownButtonFormField<int>(
      value: _selectedClaseId,
      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 10)),
      items: _materias.map((m) => DropdownMenuItem(value: m.id, child: Text(m.materia, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (v) => setState(() => _selectedClaseId = v),
    );
  }
}