import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../services/api_service.dart';

// --- ESTILOS ---
const _primaryBlue = Color(0xFF2D63ED);
const _borderColor = Color(0xFFE2E8F0);
const _mutedTextColor = Color(0xFF64748B);
const _surfaceColor = Color(0xFFF8FAFC);
const _chipColor = Color(0xFFF1F5F9); 

BoxDecoration _outlinedDecoration({Color color = Colors.white, double radius = 16}) {
  return BoxDecoration(
    color: color, 
    borderRadius: BorderRadius.circular(radius), 
    border: Border.all(color: _borderColor)
  );
}

class SubirCalificacionesScreen extends StatefulWidget {
  final int? initialGrupoId;
  const SubirCalificacionesScreen({super.key, this.initialGrupoId});

  @override
  State<SubirCalificacionesScreen> createState() => _SubirCalificacionesScreenState();
}

class _SubirCalificacionesScreenState extends State<SubirCalificacionesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, TextEditingController> _finalControllers = {};

  List<Grupo> _grupos = [];
  List<Map<String, dynamic>> _actividades = [];
  List<ResumenFinalAlumno> _finales = [];
  Grupo? _selectedGrupo;
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
    for (var c in _finalControllers.values) { c.dispose(); }
    super.dispose();
  }

  // --- CARGA DE DATOS ---
  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final profIdString = prefs.getString('saved_uid') ?? "qcT8HBPWnNQpRMGl3O32vudf1X2"; 
    setState(() => _loading = true);
    await _cargarGruposNube(profIdString);
  }

  Future<void> _cargarGruposNube(String profId) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('grupos')
          .where('profesorId', isEqualTo: profId).get();

      final grupos = snap.docs.map((doc) => Grupo(
        id: doc.data()['id'] ?? doc.id.hashCode,
        nombre: doc.data()['nombre'] ?? '',
        materia: doc.data()['materia'] ?? '',
        grupoIdReal: doc.data()['grupoIdReal'] ?? 0,
      )).toList();

      if (mounted) {
        setState(() { 
          _grupos = grupos; 
          _selectedGrupo = grupos.isNotEmpty ? grupos.first : null; 
        });
        if (_selectedGrupo != null) await _cargarContenidoGrupoNube(_selectedGrupo!);
        else setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarContenidoGrupoNube(Grupo grupo) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final actSnap = await FirebaseFirestore.instance.collection('actividades')
          .where('grupoIdReal', isEqualTo: grupo.grupoIdReal).get();
      
      final aluSnap = await FirebaseFirestore.instance.collection('alumnos')
          .where('grupoId', isEqualTo: grupo.grupoIdReal).get();

      final finales = aluSnap.docs.map((doc) {
        final data = doc.data();
        return _buildResumenVacio(Alumno(
          id: data['id'] ?? doc.id.hashCode,
          nombre: data['nombre'] ?? '',
          correo: data['correo'] ?? '',
        ));
      }).toList();

      if (mounted) {
        _replaceFinalControllers(finales);
        setState(() {
          _selectedGrupo = grupo;
          _actividades = actSnap.docs.map((d) => d.data()..['docId'] = d.id).toList();
          _finales = finales;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guardarTodoFirebase() async {
    setState(() => _loading = true);
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var alu in _finales) {
        final valor = _finalControllers[alu.alumnoId]?.text;
        if (valor != null && valor.isNotEmpty) {
          DocumentReference docRef = FirebaseFirestore.instance.collection('calificaciones').doc();
          batch.set(docRef, {
            'alumnoId': alu.alumnoId,
            'nombreAlumno': alu.nombre,
            'grupoId': _selectedGrupo?.grupoIdReal,
            'materia': _selectedGrupo?.materia,
            'calificacion': double.tryParse(valor) ?? 0.0,
            'fechaRegistro': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Guardado con éxito!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar')));
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredActividades {
    if (_searchText.isEmpty) return _actividades;
    return _actividades.where((a) => (a['titulo'] ?? '').toString().toLowerCase().contains(_searchText)).toList();
  }

  List<ResumenFinalAlumno> get _filteredFinales {
    if (_searchText.isEmpty) return _finales;
    return _finales.where((a) => a.nombre.toLowerCase().contains(_searchText) || a.alumnoId.toString().contains(_searchText)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _surfaceColor,
        appBar: AppBar(
          backgroundColor: _surfaceColor,
          elevation: 0,
          title: const Text('Calificaciones EduTrack', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _FilterPanel(
                  grupos: _grupos, 
                  selectedGrupo: _selectedGrupo, 
                  searchController: _searchController,
                  loading: _loading, 
                  onGrupoChanged: (g) => _cargarContenidoGrupoNube(g),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: _outlinedDecoration(radius: 22),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      const TabBar(
                        labelColor: _primaryBlue, 
                        indicatorColor: _primaryBlue,
                        tabs: [Tab(text: 'Actividades'), Tab(text: 'Finales')]
                      ),
                      Expanded(
                        child: _loading 
                          ? const Center(child: CircularProgressIndicator()) 
                          : TabBarView(children: [_buildActividadesTab(), _buildFinalesTab()]),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB ACTIVIDADES ---
  Widget _buildActividadesTab() {
    final acts = _filteredActividades;
    
    return Stack(
      children: [
        if (acts.isEmpty) 
          _buildEmptyState(Icons.assignment_outlined, "Sin actividades")
        else 
          ListView.builder(
            // Aumentamos el padding inferior para que el último elemento no quede tapado por el botón levantado
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 260),
            itemCount: acts.length,
            itemBuilder: (context, index) {
              final titulo = acts[index]['titulo'] ?? 'Sin título';
              final valor = acts[index]['valor']?.toString() ?? '0';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: _outlinedDecoration(radius: 18),
                child: ListTile(
                  title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _chipColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$valor %', style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryBlue)),
                  ),
                ),
              );
            },
          ),
          
        if (_selectedGrupo != null)
          Positioned(
            // ¡AQUÍ ESTÁ LA MAGIA! Lo subimos a 200 para que quede arribita de la burbuja
            bottom: 200,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _abrirCrearActividad,
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Nueva Actividad"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
              ),
            ),
          ),
      ],
    );
  }

  // --- TAB FINALES ---
  Widget _buildFinalesTab() {
    final docs = _filteredFinales;
    
    return Stack(
      children: [
        if (docs.isEmpty) 
          _buildEmptyState(Icons.people_outline, "No encontrado")
        else 
          ListView.builder(
            // Mismo ajuste de padding para que la lista respire
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 260),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final alu = docs[index];
              return Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: _outlinedDecoration(radius: 18),
                child: ListTile(
                  title: Text(alu.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: SizedBox(
                    width: 60, 
                    child: TextField(
                      controller: _finalControllers[alu.alumnoId], 
                      textAlign: TextAlign.center, 
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0-10'),
                    )
                  ),
                ),
              );
            },
          ),

        if (_selectedGrupo != null)
          Positioned(
            // Lo subimos a 200 igual que en la otra pestaña
            bottom: 200,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _guardarTodoFirebase,
              icon: const Icon(Icons.save, size: 20),
              label: const Text("Guardar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 55, 64, 186),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 48, color: _mutedTextColor), const SizedBox(height: 8), Text(text)]));
  }

  ResumenFinalAlumno _buildResumenVacio(Alumno alumno) {
    return ResumenFinalAlumno(
      id: alumno.id, alumnoId: alumno.id, nombre: alumno.nombre, correo: alumno.correo,
      calificacionFinal: null, calificacionSugerida: 0.0, promedioActividades: 0.0, 
      totalActividades: 0, entregadas: 0, noEntregadas: 0, sinRegistrar: 0,
      ultimoComentario: '', actividades: const [],
    );
  }

  void _replaceFinalControllers(List<ResumenFinalAlumno> finales) {
    for (var c in _finalControllers.values) { c.dispose(); }
    _finalControllers.clear();
    for (final a in finales) {
      _finalControllers[a.alumnoId] = TextEditingController(text: a.calificacionFinal?.toString() ?? '');
    }
  }

  Future<void> _abrirCrearActividad() async {
    final draft = await showModalBottomSheet<_NuevaActividadInput>(
      context: context, 
      isScrollControlled: true,
      builder: (_) => _CrearActividadSheet(grupo: _selectedGrupo!),
    );
    if (draft != null) {
      await FirebaseFirestore.instance.collection('actividades').add({
        'id': DateTime.now().millisecondsSinceEpoch, 
        'grupoIdReal': _selectedGrupo!.grupoIdReal,
        'titulo': draft.titulo, 
        'valor': draft.valor,
      });
      _cargarContenidoGrupoNube(_selectedGrupo!);
    }
  }
}

// --- COMPONENTES AUXILIARES ---

class _FilterPanel extends StatelessWidget {
  final List<Grupo> grupos; final Grupo? selectedGrupo; final TextEditingController searchController;
  final bool loading; final ValueChanged<Grupo> onGrupoChanged;
  const _FilterPanel({required this.grupos, required this.selectedGrupo, required this.searchController, required this.loading, required this.onGrupoChanged});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: _outlinedDecoration(radius: 14),
        child: DropdownButtonFormField<int>(
          value: selectedGrupo?.id,
          decoration: const InputDecoration(border: InputBorder.none, labelText: 'Clase'),
          items: grupos.map((g) => DropdownMenuItem(value: g.id, child: Text('${g.nombre} - ${g.materia}'))).toList(),
          onChanged: loading ? null : (v) => onGrupoChanged(grupos.firstWhere((g) => g.id == v)),
        ),
      ),
      const SizedBox(height: 12),
      TextField(controller: searchController, decoration: InputDecoration(hintText: 'Buscar...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
    ]);
  }
}

class _NuevaActividadInput {
  final String titulo; final double valor;
  _NuevaActividadInput({required this.titulo, required this.valor});
}

class _CrearActividadSheet extends StatelessWidget {
  final Grupo grupo;
  const _CrearActividadSheet({super.key, required this.grupo});

  @override
  Widget build(BuildContext context) {
    final _t = TextEditingController(); 
    final _v = TextEditingController();
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Nueva Actividad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(controller: _t, decoration: const InputDecoration(labelText: 'Título')),
        TextField(controller: _v, decoration: const InputDecoration(labelText: 'Valor %'), keyboardType: TextInputType.number),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () => Navigator.pop(context, _NuevaActividadInput(titulo: _t.text, valor: double.tryParse(_v.text) ?? 0)), child: const Text('Crear'))
      ]),
    );
  }
}