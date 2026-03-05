import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'detalle_grupo_screen.dart';

class MateriaHomeScreen extends StatefulWidget {
  final String nombreGrupo; // TI-52
  final int grupoIdReal; // id grupo físico
  final String materia; // "mate"
  final Grupo representative; // para reusar ids si hace falta

  const MateriaHomeScreen({
    super.key,
    required this.nombreGrupo,
    required this.grupoIdReal,
    required this.materia,
    required this.representative,
  });

  @override
  State<MateriaHomeScreen> createState() => _MateriaHomeScreenState();
}

class _MateriaHomeScreenState extends State<MateriaHomeScreen> {
  final Color primaryBlue = const Color(0xFF2D63ED);
  bool _loading = true;
  List<Alumno> _alumnos = [];

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  Future<void> _cargarAlumnos() async {
    try {
      // OJO: tú ya tienes endpoint por "widget.representative.id"
      final alumnos = await ApiService.getAlumnosPorGrupo(
        widget.representative.id,
      );
      if (!mounted) return;
      setState(() {
        _alumnos = alumnos;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _abrirCalificacionesRapidas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CalificacionesRapidasSheet(
        materia: widget.materia,
        grupo: widget.representative,
        alumnos: _alumnos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = "${widget.nombreGrupo} • ${widget.materia}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // acciones “reales”
                  _ActionCard(
                    icon: Icons.people_alt_rounded,
                    title: "Ver alumnos",
                    subtitle: "Lista del grupo y gestión de alumnos",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DetalleGrupoScreen(grupo: widget.representative),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.grade_rounded,
                    title: "Calificaciones rápidas",
                    subtitle: "Captura rápida por alumno (0–10)",
                    onTap: _alumnos.isEmpty
                        ? null
                        : _abrirCalificacionesRapidas,
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.checklist_rounded,
                    title: "Pasar lista (próximo)",
                    subtitle: "Registro de asistencia por día",
                    onTap: null, // lo conectamos después
                  ),
                ],
              ),
            ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFF2D63ED).withOpacity(0.10)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: enabled
                    ? const Color(0xFF2D63ED)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: enabled ? Colors.grey[500] : Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalificacionesRapidasSheet extends StatefulWidget {
  final String materia;
  final Grupo grupo;
  final List<Alumno> alumnos;

  const _CalificacionesRapidasSheet({
    required this.materia,
    required this.grupo,
    required this.alumnos,
  });

  @override
  State<_CalificacionesRapidasSheet> createState() =>
      _CalificacionesRapidasSheetState();
}

class _CalificacionesRapidasSheetState
    extends State<_CalificacionesRapidasSheet> {
  final Map<int, TextEditingController> _ctrls = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final a in widget.alumnos) {
      _ctrls[a.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    try {
      for (final a in widget.alumnos) {
        final text = _ctrls[a.id]!.text.trim();
        if (text.isEmpty) continue;

        final val = double.tryParse(text);
        if (val == null) continue;

        await ApiService.guardarCalificacion(a.id, widget.grupo.id, val);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Calificaciones guardadas"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Calificaciones rápidas • ${widget.materia}",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: ListView.builder(
                itemCount: widget.alumnos.length,
                itemBuilder: (_, i) {
                  final a = widget.alumnos[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _ctrls[a.id],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: "0-10",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text("Cerrar"),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _guardar,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Guardar"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
