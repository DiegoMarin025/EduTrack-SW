import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'pasar_lista_screen.dart';

class PanelDocenteScreen extends StatefulWidget {
  const PanelDocenteScreen({super.key});

  @override
  State<PanelDocenteScreen> createState() => _PanelDocenteScreenState();
}

class _PanelDocenteScreenState extends State<PanelDocenteScreen> {
  int _profesorId = 0;
  String _nombreProfesor = "Profesor";
  String _claseEnCurso = "Cargando...";
  String _subClaseEnCurso = "";
  int _totalGrupos = 0;
  int _totalAlumnos = 0;
  bool _isLoading = true;
  String? _errorMsg;

  // Colores (alineados al login)
  final Color primaryBlue = const Color(0xFF2D63ED);
  final Color darkBlue = const Color(0xFF1E3A8A);
  final Color bgLight = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('saved_id') ?? 0;
    final nombre = prefs.getString('saved_name') ?? "Profesor";

    setState(() {
      _profesorId = id;
      _nombreProfesor = nombre.split(' ').isNotEmpty
          ? nombre.split(' ')[0]
          : "Profesor";
    });

    if (id != 0) {
      await _cargarEstadisticas(id);
    } else {
      setState(() {
        _isLoading = false;
        _errorMsg = "No se encontró ID de usuario.";
      });
    }
  }

  Future<void> _cargarEstadisticas(int profesorId) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // Stats
      try {
        final stats = await ApiService.getProfesorStats(profesorId);
        _totalGrupos = stats['grupos'] ?? 0;
        _totalAlumnos = stats['alumnos'] ?? 0;
      } catch (_) {
        _totalGrupos = 0;
        _totalAlumnos = 0;
      }

      // ✅ IMPORTANTE: filtrar por profe
      final gruposAsignados = await ApiService.getGrupos(
        profesorId: profesorId,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;

        if (gruposAsignados.isNotEmpty) {
          final primeraClase = gruposAsignados.first;
          _claseEnCurso = primeraClase.materia;
          _subClaseEnCurso = "Grupo ${primeraClase.nombre}";
        } else {
          _claseEnCurso = "Sin clases asignadas";
          _subClaseEnCurso = "Ve a Mis Grupos";
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = "Error al conectar con el servidor.";
      });
    }
  }

  // ======================================================
  // ✅ PASAR LISTA RÁPIDO (BOTÓN DEL DASHBOARD)
  // ======================================================
  Future<void> _abrirPasarListaRapido() async {
    if (_profesorId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontró el profesor.")),
      );
      return;
    }

    try {
      // ✅ Traer materias/grupos del profe
      final clases = await ApiService.getGrupos(profesorId: _profesorId);

      if (!mounted) return;

      if (clases.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Aún no tienes grupos/materias. Ve a Mis Grupos y crea una materia.",
            ),
          ),
        );
        return;
      }

      // Agrupar por grupo físico (TI-52, 5A, etc.)
      final Map<int, List<Grupo>> porGrupoReal = {};
      for (final c in clases) {
        porGrupoReal.putIfAbsent(c.grupoIdReal, () => []);
        porGrupoReal[c.grupoIdReal]!.add(c);
      }

      // ✅ Si solo hay 1 grupo real, abre directo
      if (porGrupoReal.length == 1) {
        final bundle = porGrupoReal.values.first;
        final representative = bundle.first;

        final alumnos = await ApiService.getAlumnosPorGrupo(representative.id);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PasarListaScreen(grupo: representative, alumnos: alumnos),
          ),
        );
        return;
      }

      // ✅ Si hay varios grupos, seleccionar cuál
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (_) {
          final items = porGrupoReal.values.toList();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "¿A qué grupo vas a pasar lista?",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final bundle = items[i];
                        final rep = bundle.first;
                        final materiasCount = bundle.length;

                        return ListTile(
                          leading: const Icon(Icons.groups_rounded),
                          title: Text(
                            rep.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text("$materiasCount materias"),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            Navigator.pop(context);

                            final alumnos = await ApiService.getAlumnosPorGrupo(
                              rep.id,
                            );

                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PasarListaScreen(
                                  grupo: rep,
                                  alumnos: alumnos,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWebWide = size.width >= 900;

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryBlue))
            : _errorMsg != null
            ? _buildErrorView()
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWebWide ? 1100 : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWebWide ? 28 : 20,
                      vertical: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopHeader(context),
                        const SizedBox(height: 16),

                        // Hero card: clase en curso
                        _buildHeroClassCard(context),
                        const SizedBox(height: 16),

                        // Quick stats
                        _buildStatsRow(context, isWebWide),
                        const SizedBox(height: 18),

                        // Acciones rápidas
                        _sectionTitle("Acciones rápidas"),
                        const SizedBox(height: 12),
                        _buildQuickActionsGrid(context, isWebWide),
                        const SizedBox(height: 18),

                        // Actividad de hoy
                        _sectionTitle("Hoy"),
                        const SizedBox(height: 12),
                        _buildTodayCards(context),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // =========================
  // UI Components
  // =========================

  Widget _buildTopHeader(BuildContext context) {
    final now = DateTime.now();
    final dateText =
        "${_weekdayEs(now.weekday)} ${now.day} ${_monthEs(now.month)}";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.school_rounded, color: primaryBlue, size: 26),
        ),
        const SizedBox(width: 14),

        // Texts
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "¡Hola, $_nombreProfesor!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: darkBlue,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Bienvenido a tu panel de control",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Chip fecha + refresh
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            IconButton(
              tooltip: "Actualizar",
              onPressed: () => _cargarEstadisticas(_profesorId),
              icon: Icon(Icons.refresh_rounded, color: primaryBlue),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroClassCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Clase en curso",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _claseEnCurso,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subClaseEnCurso,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _pill(
              icon: Icons.arrow_forward_rounded,
              text: "Ver",
              onTap: () {
                // Navigator.pushNamed(context, '/misGrupos');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isWebWide) {
    final gap = isWebWide ? 16.0 : 12.0;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            number: "$_totalGrupos",
            label: "Grupos",
            icon: Icons.groups_rounded,
            tint: primaryBlue,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _statCard(
            number: "$_totalAlumnos",
            label: "Alumnos",
            icon: Icons.person_search_rounded,
            tint: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String number,
    required String label,
    required IconData icon,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tint, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isWebWide) {
    final crossAxisCount = isWebWide ? 4 : 2;

    final actions = [
      _ActionItem(
        title: "Asistencia",
        subtitle: "Pase de lista",
        icon: Icons.how_to_reg_rounded,
        tint: primaryBlue,
        // ✅ YA FUNCIONA:
        onTap: _abrirPasarListaRapido,
      ),
      _ActionItem(
        title: "Calificaciones",
        subtitle: "Evaluar rápido",
        icon: Icons.grade_rounded,
        tint: const Color(0xFFF59E0B),
        onTap: () {},
      ),
      _ActionItem(
        title: "Mis grupos",
        subtitle: "Alumnos y listas",
        icon: Icons.class_rounded,
        tint: const Color(0xFF10B981),
        onTap: () {},
      ),
      _ActionItem(
        title: "Reportes",
        subtitle: "Resumen semanal",
        icon: Icons.bar_chart_rounded,
        tint: const Color(0xFF8B5CF6),
        onTap: () {},
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWebWide ? 1.35 : 1.25,
      ),
      itemBuilder: (context, i) => _actionCard(actions[i]),
    );
  }

  Widget _actionCard(_ActionItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.tint.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: item.tint, size: 24),
            ),
            const Spacer(),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCards(BuildContext context) {
    return Column(
      children: [
        _feedCard(
          badge: "EN CLASE",
          badgeColor: primaryBlue,
          title: _claseEnCurso,
          subtitle: _subClaseEnCurso.isNotEmpty
              ? _subClaseEnCurso
              : "Sin información adicional",
          icon: Icons.school_rounded,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _feedCard(
          badge: "PENDIENTE",
          badgeColor: const Color(0xFFF59E0B),
          title: "Registrar asistencia",
          subtitle: "Marca presentes/ausentes del día en 1 minuto",
          icon: Icons.assignment_turned_in_rounded,
          // ✅ también abre la lista
          onTap: _abrirPasarListaRapido,
        ),
      ],
    );
  }

  Widget _feedCard({
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: badgeColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w900,
        color: Color(0xFF334155),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Error View
  // =========================

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 78, color: Colors.red[200]),
            const SizedBox(height: 16),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              onPressed: () => _cargarEstadisticas(_profesorId),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Reintentar",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayEs(int weekday) {
    const days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    return days[(weekday - 1).clamp(0, 6)];
  }

  String _monthEs(int month) {
    const months = [
      "Ene",
      "Feb",
      "Mar",
      "Abr",
      "May",
      "Jun",
      "Jul",
      "Ago",
      "Sep",
      "Oct",
      "Nov",
      "Dic",
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });
}
