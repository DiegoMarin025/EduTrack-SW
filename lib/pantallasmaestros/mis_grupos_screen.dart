import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class MisGruposScreen extends StatefulWidget {
  const MisGruposScreen({super.key});

  @override
  State<MisGruposScreen> createState() => _MisGruposScreenState();
}

class _MisGruposScreenState extends State<MisGruposScreen> {
  List<Grupo> _grupos = [];
  bool _loading = true;
  int _profesorId = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // 1. Obtener el ID del profesor desde la sesión guardada
  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profesorId = prefs.getInt('saved_id') ?? 0;
    });

    // Solo cargamos si tenemos un ID válido
    if (_profesorId != 0) {
      _cargarGrupos();
    } else {
      setState(() => _loading = false);
    }
  }

  // 2. Cargar grupos filtrados por el Profesor ID
  Future<void> _cargarGrupos() async {
    try {
      // Enviamos el ID para que el servidor nos devuelva SOLO mis materias
      final grupos = await ApiService.getGrupos(profesorId: _profesorId);

      if (mounted) {
        setState(() {
          _grupos = grupos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _abrirDialogoCrear() {
    if (_profesorId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No se identificó al profesor")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          DialogCrearClase(profesorId: _profesorId), // Pasamos el ID
    ).then((_) => _cargarGrupos());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogoCrear,
        label: const Text("Nueva Materia"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _grupos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.class_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No tienes materias asignadas",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _grupos.length,
              itemBuilder: (context, index) {
                final grupo = _grupos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Icon(
                        Icons.class_,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                    title: Text(
                      grupo.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      grupo.materia,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalleGrupoScreen(grupo: grupo),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ========================================================
// PANTALLA DE DETALLE (VER ALUMNOS)
// ========================================================
class DetalleGrupoScreen extends StatefulWidget {
  final Grupo grupo;
  const DetalleGrupoScreen({super.key, required this.grupo});

  @override
  State<DetalleGrupoScreen> createState() => _DetalleGrupoScreenState();
}

class _DetalleGrupoScreenState extends State<DetalleGrupoScreen> {
  List<Alumno> _alumnos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  Future<void> _cargarAlumnos() async {
    try {
      final alumnos = await ApiService.getAlumnosPorGrupo(widget.grupo.id);
      if (mounted)
        setState(() {
          _alumnos = alumnos;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _eliminarAlumno(Alumno alumno) async {
    bool confirmar =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("¿Eliminar alumno?"),
            content: Text(
              "¿Seguro que quieres sacar a ${alumno.nombre} de este grupo?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Eliminar",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmar) {
      try {
        await ApiService.eliminarAlumnoDeGrupo(
          alumno.id,
          widget.grupo.grupoIdReal,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alumno eliminado'),
            backgroundColor: Colors.orange,
          ),
        );
        _cargarAlumnos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoAgregar() {
    showDialog(
      context: context,
      builder: (context) => DialogAgregarAlumno(
        grupo: widget.grupo,
        onAlumnoAgregado: _cargarAlumnos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.grupo.nombre, style: const TextStyle(fontSize: 18)),
            Text(widget.grupo.materia, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alumnos.isEmpty
          ? const Center(child: Text("No hay alumnos inscritos"))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _alumnos.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (context, index) {
                final alumno = _alumnos[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      alumno.nombre.isNotEmpty
                          ? alumno.nombre[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(alumno.nombre),
                  subtitle: Text(alumno.correo),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _eliminarAlumno(alumno),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoAgregar,
        label: const Text("Agregar Alumno"),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ========================================================
// DIÁLOGO CREAR CLASE (CORREGIDO)
// ========================================================
class DialogCrearClase extends StatefulWidget {
  final int profesorId;

  const DialogCrearClase({super.key, required this.profesorId});

  @override
  State<DialogCrearClase> createState() => _DialogCrearClaseState();
}

class _DialogCrearClaseState extends State<DialogCrearClase> {
  List<GrupoFisico> _gruposDisponibles = [];
  int? _selectedGrupoId;
  final TextEditingController _materiaController = TextEditingController();
  bool _loadingAction = false;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  void _cargarCatalogo() async {
    try {
      final res = await ApiService.getGruposFisicos();
      if (mounted) setState(() => _gruposDisponibles = res);
    } catch (e) {}
  }

  void _crear() async {
    if (_selectedGrupoId == null || _materiaController.text.isEmpty) return;
    setState(() => _loadingAction = true);

    try {
      // ¡AQUI ESTABA EL ERROR! Ahora enviamos el profesorId correctamente
      await ApiService.crearClase(
        _selectedGrupoId!,
        _materiaController.text.trim(),
        profesorId: widget.profesorId, // <--- LÍNEA DESCOMENTADA Y CORREGIDA
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clase creada y asignada a ti correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAction = false);
        // Muestra el error completo para saber qué pasa
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nueva Materia"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _selectedGrupoId,
            hint: const Text("Selecciona el Grupo"),
            items: _gruposDisponibles
                .map(
                  (g) => DropdownMenuItem(value: g.id, child: Text(g.nombre)),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedGrupoId = val),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _materiaController,
            decoration: const InputDecoration(
              labelText: "Nombre de la Materia",
              hintText: "Ej. Matemáticas I",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _loadingAction ? null : _crear,
          child: _loadingAction
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Crear Clase"),
        ),
      ],
    );
  }
}

// Diálogo Agregar Alumno (Sin cambios, se mantiene igual)
class DialogAgregarAlumno extends StatefulWidget {
  final Grupo grupo;
  final VoidCallback onAlumnoAgregado;
  const DialogAgregarAlumno({
    super.key,
    required this.grupo,
    required this.onAlumnoAgregado,
  });
  @override
  State<DialogAgregarAlumno> createState() => _DialogAgregarAlumnoState();
}

class _DialogAgregarAlumnoState extends State<DialogAgregarAlumno> {
  final TextEditingController _searchController = TextEditingController();
  List<Alumno> _resultados = [];
  bool _buscando = false;

  void _buscar() async {
    if (_searchController.text.isEmpty) return;
    setState(() => _buscando = true);
    try {
      final res = await ApiService.buscarAlumnos(_searchController.text);
      setState(() => _resultados = res);
    } catch (e) {
    } finally {
      setState(() => _buscando = false);
    }
  }

  void _agregar(Alumno alumno) async {
    try {
      final estado = await ApiService.verificarGrupoAlumno(alumno.id);

      if (estado['enrolled'] == true) {
        if (!mounted) return;

        if (estado['group_id'] == widget.grupo.grupoIdReal) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este alumno ya está en este grupo')),
          );
          return;
        }

        bool confirmar =
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("⚠️ Alumno ya inscrito"),
                content: Text(
                  "El alumno ${alumno.nombre} ya pertenece al grupo ${estado['group_name']}.\n\n¿Quieres moverlo a ${widget.grupo.nombre}?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      "Mover",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (!confirmar) return;
      }

      await ApiService.agregarAlumnoAGrupo(alumno.id, widget.grupo.grupoIdReal);

      if (mounted) {
        Navigator.pop(context);
        widget.onAlumnoAgregado();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${alumno.nombre} agregado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Inscribir a ${widget.grupo.nombre}"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por nombre o correo...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _buscar,
                ),
              ),
              onSubmitted: (_) => _buscar(),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: _buscando
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _resultados.length,
                      itemBuilder: (context, index) {
                        final alumno = _resultados[index];
                        return ListTile(
                          title: Text(alumno.nombre),
                          subtitle: Text(alumno.correo),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.green,
                            ),
                            onPressed: () => _agregar(alumno),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
      ],
    );
  }
}
