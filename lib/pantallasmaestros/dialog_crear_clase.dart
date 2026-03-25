import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- MAGIA DE FIREBASE
import 'package:shared_preferences/shared_preferences.dart';
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
  String _profesorUid = "";

  @override
  void initState() {
    super.initState();
    _cargarDatosYCatalogo();
  }

  Future<void> _cargarDatosYCatalogo() async {
    final prefs = await SharedPreferences.getInstance();
    _profesorUid = prefs.getString('saved_uid') ?? "";
    await _cargarCatalogoFirebase();
  }

  @override
  void dispose() {
    _grupoController.dispose();
    _materiaController.dispose();
    super.dispose();
  }

  bool get _usaGrupoExistente =>
      _modoGrupo == _ModoGrupo.existente && _gruposDisponibles.isNotEmpty;

  // ======================================================
  // 💾 BUSCAMOS LOS GRUPOS EN FIREBASE (No más ApiService)
  // ======================================================
  Future<void> _cargarCatalogoFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('grupos')
          .where('profesorId', isEqualTo: _profesorUid)
          .get();

      final res = snapshot.docs.map((doc) {
        final data = doc.data();
        return GrupoFisico(
          id: data['grupoIdReal'] ?? 0,
          nombre: data['nombre'] ?? '',
        );
      }).toList();

      // Quitar duplicados por nombre
      final ids = <String>{};
      res.retainWhere((x) => ids.add(x.nombre));

      if (!mounted) return;

      setState(() {
        _gruposDisponibles = res;
        _loadingCatalogo = false;
        if (res.isNotEmpty) {
          _modoGrupo = _ModoGrupo.existente;
          _selectedGrupoId = res.first.id;
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

  // ======================================================
  // 💾 GUARDAMOS EL GRUPO EN FIREBASE (No más ApiService)
  // ======================================================
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
      // Si es nuevo, le damos un ID numérico basado en el reloj
      final idReal = _usaGrupoExistente 
          ? _selectedGrupoId 
          : DateTime.now().millisecondsSinceEpoch; 

      final nombreFinal = _usaGrupoExistente 
          ? _gruposDisponibles.firstWhere((g) => g.id == _selectedGrupoId).nombre
          : nombreGrupo;

      // MAGIA: Esto crea la colección 'grupos' automáticamente en la consola
      await FirebaseFirestore.instance.collection('grupos').add({
        'nombre': nombreFinal,
        'materia': materia,
        'profesorId': _profesorUid,
        'grupoIdReal': idReal,
        'createdAt': FieldValue.serverTimestamp(),
      });

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
                RadioListTile<_ModoGrupo>(
                  contentPadding: EdgeInsets.zero,
                  value: _ModoGrupo.existente,
                  groupValue: _modoGrupo,
                  title: const Text('Usar un grupo existente'),
                  subtitle: const Text('Agrega otra materia a un grupo ya creado'),
                  onChanged: (value) {
                    if (!_loadingAction && value != null) {
                      setState(() => _modoGrupo = value);
                    }
                  },
                ),
                RadioListTile<_ModoGrupo>(
                  contentPadding: EdgeInsets.zero,
                  value: _ModoGrupo.nuevo,
                  groupValue: _modoGrupo,
                  title: const Text('Crear un grupo nuevo'),
                  subtitle: const Text('Ponle nombre y enlazalo desde cero'),
                  onChanged: (value) {
                    if (!_loadingAction && value != null) {
                      setState(() => _modoGrupo = value);
                    }
                  },
                ),
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
                  value: _selectedGrupoId,
                  decoration: const InputDecoration(
                    labelText: 'Selecciona el grupo',
                    border: OutlineInputBorder(),
                  ),
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