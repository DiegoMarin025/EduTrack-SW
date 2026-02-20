import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORTANTE: Para obtener el ID
import '../services/api_service.dart';

class SubirCalificacionesScreen extends StatefulWidget {
  const SubirCalificacionesScreen({super.key});

  @override
  State<SubirCalificacionesScreen> createState() =>
      _SubirCalificacionesScreenState();
}

class _SubirCalificacionesScreenState extends State<SubirCalificacionesScreen> {
  List<Grupo> _grupos = [];
  int? _selectedGrupoId;
  int _profesorId = 0; // ID del profesor logueado

  bool _loading = false;
  List<Alumno> _alumnos = [];

  final Map<int, String?> _calificaciones = {};
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, bool> _isEditing = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario(); // Primero cargamos usuario, luego grupos

    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text);
    });
  }

  // 1. Obtener el ID del profesor
  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profesorId = prefs.getInt('saved_id') ?? 0;
    });

    // Solo cargamos grupos si hay un ID válido
    if (_profesorId != 0) {
      _cargarGrupos();
    }
  }

  // 2. Cargar grupos filtrados
  Future<void> _cargarGrupos() async {
    try {
      // Enviamos el profesorId para obtener solo SUS grupos
      final grupos = await ApiService.getGrupos(profesorId: _profesorId);
      if (mounted) {
        setState(() => _grupos = grupos);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando grupos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchAlumnos(int grupoId) async {
    setState(() => _loading = true);
    _alumnos.clear();
    _controllers.clear();
    _calificaciones.clear();
    _isEditing.clear();

    try {
      final alumnos = await ApiService.getAlumnosPorGrupo(grupoId);

      setState(() {
        _alumnos = alumnos;
        for (var alumno in alumnos) {
          _controllers[alumno.id] = TextEditingController();
          _isEditing[alumno.id] = false;
        }
      });

      for (var alumno in alumnos) {
        final calif = await ApiService.getCalificacion(alumno.id, grupoId);
        if (mounted && calif != null) {
          setState(() {
            _calificaciones[alumno.id] = calif;
            _controllers[alumno.id]?.text = calif;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando alumnos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _guardarCalificacion(Alumno alumno) async {
    if (_selectedGrupoId == null) return;

    final value = _controllers[alumno.id]?.text.trim();
    if (value == null || value.isEmpty) return;

    final double? numValue = double.tryParse(value);
    if (numValue == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un número válido')));
      return;
    }

    try {
      await ApiService.guardarCalificacion(
        alumno.id,
        _selectedGrupoId!,
        numValue,
      );

      setState(() => _calificaciones[alumno.id] = value);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Calificación de ${alumno.nombre} guardada."),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Alumno> get _filteredAlumnos {
    if (_searchText.isEmpty) return _alumnos;
    final q = _searchText.toLowerCase();
    return _alumnos
        .where(
          (a) =>
              a.nombre.toLowerCase().contains(q) ||
              a.correo.toLowerCase().contains(q),
        )
        .toList();
  }

  Widget _buildCalificacionControl(Alumno alumno) {
    final bool editing = _isEditing[alumno.id] ?? false;
    final String? calif = _calificaciones[alumno.id];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFE8D9FF).withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),

        leading: const CircleAvatar(
          radius: 26,
          backgroundColor: Color(0xFFB388EB),
          child: Icon(Icons.person, size: 30, color: Color(0xFF4B0082)),
        ),

        title: Text(
          alumno.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),

        subtitle: Text(alumno.correo),

        trailing: editing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFB388EB)),
                    ),
                    child: TextField(
                      controller: _controllers[alumno.id],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                    onPressed: () {
                      _guardarCalificacion(alumno);
                      setState(() => _isEditing[alumno.id] = false);
                    },
                  ),
                ],
              )
            :
              // ====== PALETA MORADA APLICADA ======
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8D9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      calif == null || calif.isEmpty ? "—" : calif.toString(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B0082),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Color(0xFF6A0DAD),
                      size: 26,
                    ),
                    onPressed: () {
                      setState(() => _isEditing[alumno.id] = true);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 26),
                    onPressed: () {
                      setState(() {
                        _controllers[alumno.id]?.text = '';
                        _calificaciones[alumno.id] = null;
                      });
                    },
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SELECTOR DE GRUPO
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: DropdownButtonFormField<int>(
                value: _selectedGrupoId,
                decoration: const InputDecoration(border: InputBorder.none),
                hint: const Text("Selecciona un grupo"),
                items: _grupos.map((g) {
                  return DropdownMenuItem(
                    value: g.id,
                    child: Text("${g.nombre} - ${g.materia}"),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    setState(() => _selectedGrupoId = id);
                    _fetchAlumnos(id);
                  }
                },
              ),
            ),

            const SizedBox(height: 15),

            // BARRA DE BÚSQUEDA
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Color(0xFF6A0DAD)),
                  hintText: "Buscar alumno...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // LISTA DE ALUMNOS
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAlumnos.isEmpty
                  ? Center(
                      child: Text(
                        _selectedGrupoId == null
                            ? "Selecciona un grupo primero"
                            : "No hay alumnos en este grupo",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredAlumnos.length,
                      itemBuilder: (_, i) {
                        final alumno = _filteredAlumnos[i];
                        return _buildCalificacionControl(alumno);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
