import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DetalleGrupoScreen extends StatefulWidget {
  final Grupo grupo;

  const DetalleGrupoScreen({super.key, required this.grupo});

  @override
  State<DetalleGrupoScreen> createState() => _DetalleGrupoScreenState();
}

class _DetalleGrupoScreenState extends State<DetalleGrupoScreen> {
  List<Alumno> _alumnos = [];
  bool _loading = true;

  final Color primaryBlue = const Color(0xFF2D63ED);

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  Future<void> _cargarAlumnos() async {
    try {
      final alumnos = await ApiService.getAlumnosPorGrupo(widget.grupo.id);

      if (mounted) {
        setState(() {
          _alumnos = alumnos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===============================
  // 🔵 AGREGAR ALUMNO (NUEVO)
  // ===============================
  void _mostrarDialogoAgregarAlumno() {
    final nombreController = TextEditingController();
    final correoController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Agregar alumno"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: "Nombre completo"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: correoController,
              decoration: const InputDecoration(
                labelText: "Correo electrónico",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Guardar"),
            onPressed: () async {
              final nombre = nombreController.text.trim();
              final correo = correoController.text.trim();

              if (nombre.isEmpty || correo.isEmpty) return;

              try {
                // 1️⃣ Crear alumno
                final nuevoAlumno = await ApiService.crearAlumno(
                  nombre: nombre,
                  correo: correo,
                );

                // 2️⃣ Asignarlo al grupo
                await ApiService.agregarAlumnoAGrupo(
                  nuevoAlumno.id,
                  widget.grupo.grupoIdReal,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _cargarAlumnos();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Alumno agregado correctamente"),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: ${e.toString()}")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grupo.nombre),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,

      
        actions: [
          IconButton(
            tooltip: "Agregar alumno",
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: _mostrarDialogoAgregarAlumno,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : _alumnos.isEmpty
          ? const Center(child: Text("Aún no hay alumnos en este grupo"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alumnos.length,
              itemBuilder: (context, index) {
                final alumno = _alumnos[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        alumno.nombre.isNotEmpty
                            ? alumno.nombre[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(alumno.nombre),
                    subtitle: Text(alumno.correo),
                  ),
                );
              },
            ),
    );
  }
}
