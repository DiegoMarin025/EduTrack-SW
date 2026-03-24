import 'package:flutter/material.dart';

import '../services/api_service.dart';

enum _ModoGrupo { existente, nuevo }

class DialogCrearClase extends StatefulWidget {
  final int profesorId;

  const DialogCrearClase({super.key, required this.profesorId});

  @override
  State<DialogCrearClase> createState() => _DialogCrearClaseState();
}

class _DialogCrearClaseState extends State<DialogCrearClase> {
  List<GrupoFisico> _gruposDisponibles = [];
  _ModoGrupo _modoGrupo = _ModoGrupo.nuevo;
  int? _selectedGrupoId;
  final TextEditingController _grupoController = TextEditingController();
  final TextEditingController _materiaController = TextEditingController();
  bool _loadingCatalogo = true;
  bool _loadingAction = false;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _grupoController.dispose();
    _materiaController.dispose();
    super.dispose();
  }

  bool get _usaGrupoExistente =>
      _modoGrupo == _ModoGrupo.existente && _gruposDisponibles.isNotEmpty;

  Future<void> _cargarCatalogo() async {
    try {
      final res = await ApiService.getGruposFisicos();
      if (!mounted) return;

      setState(() {
        _gruposDisponibles = res;
        _loadingCatalogo = false;
        if (res.isNotEmpty) {
          _modoGrupo = _ModoGrupo.existente;
          _selectedGrupoId ??= res.first.id;
        } else {
          _modoGrupo = _ModoGrupo.nuevo;
          _selectedGrupoId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gruposDisponibles = [];
        _modoGrupo = _ModoGrupo.nuevo;
        _selectedGrupoId = null;
        _loadingCatalogo = false;
      });
    }
  }

  void _mostrarError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _crear() async {
    final materia = _materiaController.text.trim();
    final nombreGrupo = _grupoController.text.trim();

    if (materia.isEmpty) {
      _mostrarError('Escribe el nombre de la materia');
      return;
    }

    if (_usaGrupoExistente) {
      if (_selectedGrupoId == null) {
        _mostrarError('Selecciona un grupo');
        return;
      }
    } else if (nombreGrupo.isEmpty) {
      _mostrarError('Escribe el nombre del grupo');
      return;
    }

    setState(() => _loadingAction = true);
    try {
      await ApiService.crearClase(
        grupoId: _usaGrupoExistente ? _selectedGrupoId : null,
        nombreGrupo: _usaGrupoExistente ? null : nombreGrupo,
        nombreMateria: materia,
        profesorId: widget.profesorId,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _mostrarError("Error: $e");
    } finally {
      if (mounted) {
        setState(() => _loadingAction = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneGrupos = _gruposDisponibles.isNotEmpty;

    return AlertDialog(
      title: const Text('Crear grupo o materia'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadingCatalogo) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else ...[
              if (tieneGrupos) ...[
                const Text(
                  'Que quieres hacer?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                RadioGroup<_ModoGrupo>(
                  groupValue: _modoGrupo,
                  onChanged: (value) {
                    if (_loadingAction || value == null) return;
                    setState(() => _modoGrupo = value);
                  },
                  child: Column(
                    children: [
                      RadioListTile<_ModoGrupo>(
                        contentPadding: EdgeInsets.zero,
                        value: _ModoGrupo.existente,
                        enabled: !_loadingAction,
                        title: const Text('Usar un grupo existente'),
                        subtitle: const Text(
                          'Agrega otra materia a un grupo ya creado',
                        ),
                      ),
                      RadioListTile<_ModoGrupo>(
                        contentPadding: EdgeInsets.zero,
                        value: _ModoGrupo.nuevo,
                        enabled: !_loadingAction,
                        title: const Text('Crear un grupo nuevo'),
                        subtitle: const Text(
                          'Ponle nombre y enlazalo desde cero',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Aun no hay grupos creados. Escribe el nombre del primero y su materia.',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_usaGrupoExistente) ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedGrupoId,
                  hint: const Text('Selecciona el grupo'),
                  items: _gruposDisponibles.map((g) {
                    return DropdownMenuItem(value: g.id, child: Text(g.nombre));
                  }).toList(),
                  onChanged: _loadingAction
                      ? null
                      : (value) => setState(() => _selectedGrupoId = value),
                ),
              ] else ...[
                TextField(
                  controller: _grupoController,
                  enabled: !_loadingAction,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del grupo',
                    hintText: 'Ej. 1B',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _materiaController,
                enabled: !_loadingAction,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la materia',
                  hintText: 'Ej. Matematicas',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loadingAction
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loadingCatalogo || _loadingAction ? null : _crear,
          child: _loadingAction
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}
