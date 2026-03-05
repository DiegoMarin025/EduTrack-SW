import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  @override
  void dispose() {
    _materiaController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogo() async {
    try {
      final res = await ApiService.getGruposFisicos();
      if (mounted) setState(() => _gruposDisponibles = res);
    } catch (_) {}
  }

  Future<void> _crear() async {
    if (_selectedGrupoId == null || _materiaController.text.trim().isEmpty)
      return;

    setState(() => _loadingAction = true);
    try {
      await ApiService.crearClase(
        _selectedGrupoId!,
        _materiaController.text.trim(),
        profesorId: widget.profesorId,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAction = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nueva materia"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _selectedGrupoId,
            hint: const Text("Selecciona el grupo"),
            items: _gruposDisponibles
                .map(
                  (g) => DropdownMenuItem(value: g.id, child: Text(g.nombre)),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedGrupoId = val),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _materiaController,
            decoration: const InputDecoration(
              labelText: "Nombre de la materia",
              hintText: "Ej. Matemáticas",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loadingAction
              ? null
              : () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _loadingAction ? null : _crear,
          child: _loadingAction
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Crear"),
        ),
      ],
    );
  }
}
