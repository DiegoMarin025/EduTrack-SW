import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'detalle_grupo_screen.dart';
import 'dialog_crear_clase.dart';
import 'materia_home_screen.dart';

// ===============================
// MIS GRUPOS (REDISEÑO PRIMARIA)
// ===============================
class MisGruposScreen extends StatefulWidget {
  const MisGruposScreen({super.key});

  @override
  State<MisGruposScreen> createState() => _MisGruposScreenState();
}

class _MisGruposScreenState extends State<MisGruposScreen> {
  List<Grupo> _clases = [];
  bool _loading = true;
  int _profesorId = 0;

  // UI (alineado con tu login)
  final Color primaryBlue = const Color(0xFF2D63ED);
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF0F172A);
  final Color textSoft = const Color(0xFF64748B);
  final Color border = const Color(0xFFE2E8F0);

  // Para expandir/cerrar un grupo
  final Set<int> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profesorId = prefs.getInt('saved_id') ?? 0;
    });

    if (_profesorId != 0) {
      _cargarClases();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _cargarClases() async {
    setState(() => _loading = true);
    try {
      final grupos = await ApiService.getGrupos(profesorId: _profesorId);
      if (!mounted) return;
      setState(() {
        _clases = grupos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
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
      builder: (context) => DialogCrearClase(profesorId: _profesorId),
    ).then((_) => _cargarClases());
  }

  // Agrupa materias por grupo físico (TI-52, 5°A, etc.)
  List<_GrupoBundle> _buildBundles() {
    final Map<int, _GrupoBundle> map = {};

    for (final c in _clases) {
      final key = c.grupoIdReal; // grupo físico
      map.putIfAbsent(
        key,
        () => _GrupoBundle(grupoIdReal: key, nombreGrupo: c.nombre, items: []),
      );
      map[key]!.items.add(c);
    }

    final list = map.values.toList();

    // Ordena por nombre para que se vea estable
    list.sort(
      (a, b) =>
          a.nombreGrupo.toLowerCase().compareTo(b.nombreGrupo.toLowerCase()),
    );
    return list;
  }

  void _toggleExpand(int grupoIdReal) {
    setState(() {
      if (_expandedGroups.contains(grupoIdReal)) {
        _expandedGroups.remove(grupoIdReal);
      } else {
        _expandedGroups.add(grupoIdReal);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bundles = _buildBundles();

    return Scaffold(
      backgroundColor: bgLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogoCrear,
        label: const Text("Nueva materia"),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: primaryBlue))
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: ListView(
                  children: [
                    // Encabezado “humano” para que no se sienta vacío
                    Text(
                      "Tu salón y tus materias",
                      style: TextStyle(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Aquí gestionas tu grupo: alumnos, lista del día y calificaciones.",
                      style: TextStyle(
                        color: textSoft,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Si está vacío: onboarding (no se ve “pantalla IA”)
                    if (bundles.isEmpty) ...[
                      _OnboardingEmpty(
                        primaryBlue: primaryBlue,
                        border: border,
                        textDark: textDark,
                        textSoft: textSoft,
                        onCreate: _abrirDialogoCrear,
                      ),
                      const SizedBox(height: 12),
                      _TipCard(
                        border: border,
                        textSoft: textSoft,
                        textDark: textDark,
                      ),
                    ] else ...[
                      // “Hoy” (por ahora es visual; luego lo conectamos a asistencia)
                      _TodayCard(
                        primaryBlue: primaryBlue,
                        border: border,
                        textDark: textDark,
                        textSoft: textSoft,
                      ),
                      const SizedBox(height: 14),

                      // Lista de “Mi salón”
                      Text(
                        "Mis grupos",
                        style: TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),

                      for (final bundle in bundles) ...[
                        _GroupCard(
                          primaryBlue: primaryBlue,
                          border: border,
                          textDark: textDark,
                          textSoft: textSoft,
                          bundle: bundle,
                          expanded: _expandedGroups.contains(
                            bundle.grupoIdReal,
                          ),
                          onToggleExpand: () =>
                              _toggleExpand(bundle.grupoIdReal),
                          onOpenAlumnos: () {
                            // Abrimos alumnos con el primer item (tiene ids correctos)
                            final representative = bundle.items.first;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetalleGrupoScreen(grupo: representative),
                              ),
                            );
                          },
                          onPasarLista: () {
                            // Por ahora usamos alumnos como “lista”
                            final representative = bundle.items.first;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetalleGrupoScreen(grupo: representative),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

// ===============================
// UI COMPONENTS
// ===============================

class _OnboardingEmpty extends StatelessWidget {
  final Color primaryBlue;
  final Color border;
  final Color textDark;
  final Color textSoft;
  final VoidCallback onCreate;

  const _OnboardingEmpty({
    required this.primaryBlue,
    required this.border,
    required this.textDark,
    required this.textSoft,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.school_rounded, color: primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Aún no tienes grupos",
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Crea tu primer grupo y agrega una materia. Luego podrás registrar alumnos y pasar lista.",
            style: TextStyle(
              color: textSoft,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              "Crear mi primer grupo/materia",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final Color border;
  final Color textSoft;
  final Color textDark;

  const _TipCard({
    required this.border,
    required this.textSoft,
    required this.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tip: Si tu escuela usa un solo grupo (por ejemplo 5°B), crea ese grupo una vez y luego agrega tus materias.",
              style: TextStyle(
                color: textSoft,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final Color primaryBlue;
  final Color border;
  final Color textDark;
  final Color textSoft;

  const _TodayCard({
    required this.primaryBlue,
    required this.border,
    required this.textDark,
    required this.textSoft,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = "${now.day}/${now.month}/${now.year}";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.today_rounded, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hoy • $label",
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Asistencia: pendiente • Calificaciones: opcional",
                  style: TextStyle(
                    color: textSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              "Pendiente",
              style: TextStyle(
                color: textSoft,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Color primaryBlue;
  final Color border;
  final Color textDark;
  final Color textSoft;
  final _GrupoBundle bundle;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onOpenAlumnos;
  final VoidCallback onPasarLista;

  const _GroupCard({
    required this.primaryBlue,
    required this.border,
    required this.textDark,
    required this.textSoft,
    required this.bundle,
    required this.expanded,
    required this.onToggleExpand,
    required this.onOpenAlumnos,
    required this.onPasarLista,
  });

  @override
  Widget build(BuildContext context) {
    final materias = bundle.items.map((e) => e.materia).toList();
    final materiasText = materias.length == 1
        ? "1 materia"
        : "${materias.length} materias";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.groups_rounded, color: primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bundle.nombreGrupo,
                          style: TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          materiasText,
                          style: TextStyle(
                            color: textSoft,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),

          // Acciones rápidas (más “primaria”)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPasarLista,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: border),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.checklist_rounded, size: 18),
                    label: const Text(
                      "Pasar lista",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onOpenAlumnos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.people_alt_rounded, size: 18),
                    label: const Text(
                      "Alumnos",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Materias (expandible)
          if (expanded) ...[
            Container(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Materias",
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: materias.map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Botón secundario (cuando quieras conectar a calificaciones)
                  Row(
                    children: [
                      const Icon(
                        Icons.grade_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "",
                          style: TextStyle(
                            color: textSoft,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Agrupación local
class _GrupoBundle {
  final int grupoIdReal;
  final String nombreGrupo;
  final List<Grupo> items; // cada item es una materia (clase)

  _GrupoBundle({
    required this.grupoIdReal,
    required this.nombreGrupo,
    required this.items,
  });
}


