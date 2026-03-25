import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- LA NUBE
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
    _cargarAlumnosFirebase();
  }

  // ======================================================
  // 💾 BUSCAR ALUMNOS EN FIREBASE
  // ======================================================
  Future<void> _cargarAlumnosFirebase() async {
    setState(() => _loading = true);
    try {
      // Buscamos alumnos que tengan el ID de este grupo
      final snapshot = await FirebaseFirestore.instance
          .collection('alumnos')
          .where('grupoId', isEqualTo: widget.grupo.grupoIdReal)
          .get();

      final listaAlumnos = snapshot.docs.map((doc) {
        final data = doc.data();
        return Alumno(
          id: data['id'] ?? doc.id.hashCode,
          nombre: data['nombre'] ?? 'Sin nombre',
          correo: data['correo'] ?? 'Sin correo',
        );
      }).toList();

      // Ordenar por nombre alfabéticamente
      listaAlumnos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

      if (mounted) {
        setState(() {
          _alumnos = listaAlumnos;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _alumnos = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando alumnos: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ===============================
  // 🔵 AGREGAR ALUMNO A FIREBASE
  // ===============================
  void _mostrarDialogoAgregarAlumno() {
    final nombreController = TextEditingController();
    final correoController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Para que no lo cierren por accidente mientras guarda
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Agregar alumno", style: TextStyle(fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !isSaving,
                  decoration: const InputDecoration(labelText: "Nombre completo", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: correoController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Correo electrónico", border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving ? null : () async {
                  final nombre = nombreController.text.trim();
                  final correo = correoController.text.trim();

                  if (nombre.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ponle un nombre al alumno")));
                    return;
                  }

                  setDialogState(() => isSaving = true);

                  try {
                    // Creamos el alumno directo en Firebase
                    await FirebaseFirestore.instance.collection('alumnos').add({
                      'id': DateTime.now().millisecondsSinceEpoch, // ID único numérico
                      'nombre': nombre,
                      'correo': correo,
                      'grupoId': widget.grupo.grupoIdReal, // Lo amarramos al grupo
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) {
                      Navigator.pop(dialogContext); // Cerramos el modal
                      await _cargarAlumnosFirebase(); // Recargamos la lista atrás

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Alumno agregado correctamente")),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
                    );
                  }
                },
                child: isSaving 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text("Guardar"),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grupo.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_rounded, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("Aún no hay alumnos en este grupo", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _mostrarDialogoAgregarAlumno, 
                    icon: const Icon(Icons.add), 
                    label: const Text("Agregar mi primer alumno"),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
                  )
                ],
              )
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alumnos.length,
              itemBuilder: (context, index) {
                final alumno = _alumnos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: primaryBlue.withOpacity(0.1),
                      child: Text(
                        alumno.nombre.isNotEmpty ? alumno.nombre[0].toUpperCase() : '?',
                        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Text(alumno.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    subtitle: Text(alumno.correo.isEmpty ? "Sin correo" : alumno.correo, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ),
                );
              },
            ),
    );
  }
}