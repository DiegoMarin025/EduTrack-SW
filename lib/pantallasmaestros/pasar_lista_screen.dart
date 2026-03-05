import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart'; // usa tus modelos Alumno/Grupo

/// ESTADOS DE ASISTENCIA
enum EstadoAsistencia { presente, ausente, retardo }

class PasarListaScreen extends StatefulWidget {
  final Grupo grupo;
  final List<Alumno> alumnos;

  const PasarListaScreen({
    super.key,
    required this.grupo,
    required this.alumnos,
  });

  @override
  State<PasarListaScreen> createState() => _PasarListaScreenState();
}

class _PasarListaScreenState extends State<PasarListaScreen> {
  final Color primaryBlue = const Color(0xFF2D63ED);
  final Color bgLight = const Color(0xFFF8FAFC);

  late DateTime _fecha;
  final Map<int, EstadoAsistencia> _estadoPorAlumno = {};
  final Map<int, TextEditingController> _notaPorAlumno = {};

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fecha = DateTime.now();

    // Por defecto: todos "Presente" (puedes cambiar a "Ausente" si prefieres)
    for (final a in widget.alumnos) {
      _estadoPorAlumno[a.id] = EstadoAsistencia.presente;
      _notaPorAlumno[a.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _notaPorAlumno.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _fechaTexto() => DateFormat('dd/MM/yyyy').format(_fecha);

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) {
      setState(() => _fecha = picked);
    }
  }

  void _marcarTodos(EstadoAsistencia estado) {
    setState(() {
      for (final a in widget.alumnos) {
        _estadoPorAlumno[a.id] = estado;
      }
    });
  }

  int _contar(EstadoAsistencia estado) {
    int c = 0;
    for (final v in _estadoPorAlumno.values) {
      if (v == estado) c++;
    }
    return c;
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);

    try {
      // ✅ Por ahora: solo confirmamos y dejamos listo para backend.
      // Cuando tengas endpoint, aquí mandamos:
      // await ApiService.guardarAsistencia(...)

      // Simulación breve (para que se sienta “real”)
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Lista guardada"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _chipColor(EstadoAsistencia estado, bool selected) {
    if (!selected) return const Color(0xFFF1F5F9);
    switch (estado) {
      case EstadoAsistencia.presente:
        return const Color(0xFFDCFCE7); // verde suave
      case EstadoAsistencia.ausente:
        return const Color(0xFFFEE2E2); // rojo suave
      case EstadoAsistencia.retardo:
        return const Color(0xFFFFEDD5); // naranja suave
    }
  }

  Color _chipTextColor(EstadoAsistencia estado, bool selected) {
    if (!selected) return const Color(0xFF64748B);
    switch (estado) {
      case EstadoAsistencia.presente:
        return const Color(0xFF166534);
      case EstadoAsistencia.ausente:
        return const Color(0xFF991B1B);
      case EstadoAsistencia.retardo:
        return const Color(0xFF9A3412);
    }
  }

  String _labelEstado(EstadoAsistencia e) {
    switch (e) {
      case EstadoAsistencia.presente:
        return "Presente";
      case EstadoAsistencia.ausente:
        return "Ausente";
      case EstadoAsistencia.retardo:
        return "Retardo";
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentes = _contar(EstadoAsistencia.presente);
    final ausentes = _contar(EstadoAsistencia.ausente);
    final retardos = _contar(EstadoAsistencia.retardo);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          "Pasar lista • ${widget.grupo.nombre}",
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Guardar lista",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // ====== HEADER SIMPLE (FECHA + ACCIONES) ======
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.grupo.materia,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _seleccionarFecha,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            color: const Color(0xFFF8FAFC),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: primaryBlue,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Fecha: ${_fechaTexto()}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<String>(
                      tooltip: "Acciones rápidas",
                      onSelected: (v) {
                        if (v == "todos_presente") {
                          _marcarTodos(EstadoAsistencia.presente);
                        } else if (v == "todos_ausente") {
                          _marcarTodos(EstadoAsistencia.ausente);
                        } else if (v == "todos_retardo") {
                          _marcarTodos(EstadoAsistencia.retardo);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "todos_presente",
                          child: Text("Marcar todos: Presente"),
                        ),
                        PopupMenuItem(
                          value: "todos_ausente",
                          child: Text("Marcar todos: Ausente"),
                        ),
                        PopupMenuItem(
                          value: "todos_retardo",
                          child: Text("Marcar todos: Retardo"),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          color: Colors.white,
                        ),
                        child: Icon(Icons.tune_rounded, color: primaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Resumen
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ResumenChip(
                      label: "Presentes: $presentes",
                      bg: const Color(0xFFDCFCE7),
                      fg: const Color(0xFF166534),
                    ),
                    _ResumenChip(
                      label: "Ausentes: $ausentes",
                      bg: const Color(0xFFFEE2E2),
                      fg: const Color(0xFF991B1B),
                    ),
                    _ResumenChip(
                      label: "Retardos: $retardos",
                      bg: const Color(0xFFFFEDD5),
                      fg: const Color(0xFF9A3412),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ====== LISTA ======
          Expanded(
            child: widget.alumnos.isEmpty
                ? const Center(child: Text("No hay alumnos en este grupo"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.alumnos.length,
                    itemBuilder: (context, index) {
                      final a = widget.alumnos[index];
                      final estado = _estadoPorAlumno[a.id]!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: primaryBlue.withOpacity(
                                    0.12,
                                  ),
                                  foregroundColor: primaryBlue,
                                  child: Text(
                                    a.nombre.isNotEmpty
                                        ? a.nombre[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        a.correo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Botones grandes
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: EstadoAsistencia.values.map((e) {
                                final selected = (estado == e);
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(
                                    _labelEstado(e),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _chipTextColor(e, selected),
                                    ),
                                  ),
                                  selectedColor: _chipColor(e, true),
                                  backgroundColor: _chipColor(e, false),
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: selected
                                          ? Colors.transparent
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  onSelected: (_) {
                                    setState(() => _estadoPorAlumno[a.id] = e);
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 10),

                            // Nota opcional (muy útil para profe)
                            TextField(
                              controller: _notaPorAlumno[a.id],
                              decoration: const InputDecoration(
                                hintText:
                                    "Nota (opcional) • Ej. llegó 10 min tarde",
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResumenChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _ResumenChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
