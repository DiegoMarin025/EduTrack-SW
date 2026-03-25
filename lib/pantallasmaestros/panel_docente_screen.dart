import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- CONEXIÓN REAL
import '../pantallas/ayuda_screen.dart';
import '../services/api_service.dart';
import 'mensajes_padres_screen.dart';
import 'materia_home_screen.dart';
import 'mis_grupos_screen.dart';
import 'subir_calificaciones_screen.dart';
import 'teacher_navigation_helper.dart';

class PanelDocenteScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToSection;
  const PanelDocenteScreen({super.key, this.onNavigateToSection});

  @override
  State<PanelDocenteScreen> createState() => _PanelDocenteScreenState();
}

class _PanelDocenteScreenState extends State<PanelDocenteScreen> {
  String _profesorUid = "";
  String _nombreProfesor = "Profesor";
  
  // Datos reales de Firebase
  String _claseEnCurso = "Sin clases configuradas";
  String _subClaseEnCurso = "Crea un grupo para comenzar";
  Grupo? _claseEnCursoGrupo;
  int _totalGrupos = 0;
  int _totalAlumnos = 0;
  
  bool _isLoading = true;
  String? _errorMsg;

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
    final uid = prefs.getString('saved_uid') ?? "";
    final nombre = prefs.getString('saved_name') ?? "Profesor";

    setState(() {
      _profesorUid = uid;
      _nombreProfesor = nombre.split(' ').isNotEmpty ? nombre.split(' ')[0] : "Profesor";
    });

    if (_profesorUid.isNotEmpty) {
      await _cargarEstadisticasFirebase();
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ======================================================
  // 💾 LÓGICA DE FIREBASE (Datos Reales)
  // ======================================================
  Future<void> _cargarEstadisticasFirebase() async {
    setState(() => _isLoading = true);
    try {
      // 1. Contar Grupos
      final gruposSnapshot = await FirebaseFirestore.instance
          .collection('grupos')
          .where('profesorId', isEqualTo: _profesorUid)
          .get();

      // 2. Contar Alumnos (Sumando los alumnos de cada grupo del profe)
      int alumnosContador = 0;
      if (gruposSnapshot.docs.isNotEmpty) {
        // Obtenemos los IDs reales de los grupos para buscar a sus alumnos
        List<int> idsGrupos = gruposSnapshot.docs
            .map((d) => (d.data()['grupoIdReal'] as num).toInt())
            .toList();

        final alumnosSnapshot = await FirebaseFirestore.instance
            .collection('alumnos')
            .where('grupoId', whereIn: idsGrupos)
            .get();
        alumnosContador = alumnosSnapshot.docs.length;
      }

      if (!mounted) return;

      setState(() {
        _totalGrupos = gruposSnapshot.docs.length;
        _totalAlumnos = alumnosContador;

        if (gruposSnapshot.docs.isNotEmpty) {
          final primeraClase = gruposSnapshot.docs.first.data();
          _claseEnCurso = primeraClase['materia'] ?? "Sin materia";
          _subClaseEnCurso = "Grupo ${primeraClase['nombre']}";
          
          _claseEnCursoGrupo = Grupo(
            id: primeraClase['id'] ?? gruposSnapshot.docs.first.id.hashCode,
            nombre: primeraClase['nombre'] ?? '',
            materia: primeraClase['materia'] ?? '',
            grupoIdReal: primeraClase['grupoIdReal'] ?? 0,
          );
        } else {
          _claseEnCurso = "¡Bienvenido!";
          _subClaseEnCurso = "Crea tu primer grupo en 'Materias'";
          _claseEnCursoGrupo = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = "Error al sincronizar con la nube.";
      });
    }
  }

  Future<void> _abrirPasarListaRapido() async {
    await TeacherNavigationHelper.openQuickAttendance(
      context: context,
      profesorId: _profesorUid,
    );
  }

  // Navegación (Diseño intacto)
  void _abrirApartado(int index) {
    if (widget.onNavigateToSection != null) {
      widget.onNavigateToSection!(index);
      return;
    }
    final builders = <int, WidgetBuilder>{
      1: (_) => const MisGruposScreen(),
      2: (_) => const SubirCalificacionesScreen(),
      4: (_) => const AyudaScreen(),
    };
    final builder = builders[index];
    if (builder != null) Navigator.push(context, MaterialPageRoute(builder: builder));
  }

  void _abrirMensajesPadres() {
    if (_profesorUid.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MensajesPadresScreen(profesorId: _profesorUid.hashCode),
    ));
  }

  void _abrirClaseEnCurso() {
    if (_claseEnCursoGrupo == null) {
      _abrirApartado(1); // Si no hay clase, mandarlo a crear una
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MateriaHomeScreen(
        nombreGrupo: _claseEnCursoGrupo!.nombre,
        grupoIdReal: _claseEnCursoGrupo!.grupoIdReal,
        materia: _claseEnCursoGrupo!.materia,
        representative: _claseEnCursoGrupo!,
      ),
    ));
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
                      constraints: BoxConstraints(maxWidth: isWebWide ? 1100 : double.infinity),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: isWebWide ? 28 : 20, vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopHeader(context),
                            const SizedBox(height: 16),
                            _buildHeroClassCard(context),
                            const SizedBox(height: 16),
                            _buildStatsRow(context, isWebWide),
                            const SizedBox(height: 18),
                            _sectionTitle("Acciones rápidas"),
                            const SizedBox(height: 12),
                            _buildQuickActionsGrid(context, isWebWide),
                            const SizedBox(height: 18),
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

  // Componentes de UI (Diseño de Diego y Jorge respetado)
  Widget _buildTopHeader(BuildContext context) {
    final now = DateTime.now();
    final dateText = "${_weekdayEs(now.weekday)} ${now.day} ${_monthEs(now.month)}";
    return Row(
      children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.school_rounded, color: primaryBlue, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("¡Hola, $_nombreProfesor!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: darkBlue, height: 1.1)),
            const SizedBox(height: 6),
            const Text("Bienvenido a tu panel de control", style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(children: [
              Icon(Icons.calendar_month_rounded, size: 18, color: primaryBlue),
              const SizedBox(width: 8),
              Text(dateText, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            ]),
          ),
          IconButton(icon: Icon(Icons.refresh_rounded, color: primaryBlue), onPressed: _cargarEstadisticasFirebase),
        ]),
      ],
    );
  }

  Widget _buildHeroClassCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryBlue, darkBlue]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("MI MATERIA", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
              const SizedBox(height: 6),
              Text(_claseEnCurso, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text(_subClaseEnCurso, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
          _pill(icon: Icons.arrow_forward_rounded, text: "Abrir", onTap: _abrirClaseEnCurso),
        ]),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isWebWide) {
    return Row(children: [
      Expanded(child: _statCard(number: "$_totalGrupos", label: "Grupos", icon: Icons.groups_rounded, tint: primaryBlue)),
      const SizedBox(width: 12),
      Expanded(child: _statCard(number: "$_totalAlumnos", label: "Alumnos", icon: Icons.person_search_rounded, tint: const Color(0xFF10B981))),
    ]);
  }

  Widget _statCard({required String number, required String label, required IconData icon, required Color tint}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: tint.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: tint, size: 24),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ]),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isWebWide) {
    final actions = [
      _ActionItem(title: "Asistencia", subtitle: "Pase de lista", icon: Icons.how_to_reg_rounded, tint: primaryBlue, onTap: _abrirPasarListaRapido),
      _ActionItem(title: "Calificaciones", subtitle: "Evaluar rápido", icon: Icons.grade_rounded, tint: const Color(0xFFF59E0B), onTap: () => _abrirApartado(2)),
      _ActionItem(title: "Materias", subtitle: "Grupos y alumnos", icon: Icons.class_rounded, tint: const Color(0xFF10B981), onTap: () => _abrirApartado(1)),
      _ActionItem(title: "Padres", subtitle: "Mensajes", icon: Icons.family_restroom_rounded, tint: const Color(0xFF8B5CF6), onTap: _abrirMensajesPadres),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isWebWide ? 4 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
      itemBuilder: (context, i) => _actionCard(actions[i]),
    );
  }

 Widget _actionCard(_ActionItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: item.tint.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(item.icon, color: item.tint, size: 24),
          ),
          const Spacer(),
          Text(item.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(item.subtitle, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
  Widget _buildTodayCards(BuildContext context) {
    return Column(children: [
      _feedCard(badge: "ACCESO RÁPIDO", badgeColor: primaryBlue, title: _claseEnCurso, subtitle: _subClaseEnCurso, icon: Icons.school_rounded, onTap: _abrirClaseEnCurso),
      const SizedBox(height: 12),
      _feedCard(badge: "PENDIENTE", badgeColor: const Color(0xFFF59E0B), title: "Registrar asistencia", subtitle: "No olvides pasar lista hoy", icon: Icons.assignment_turned_in_rounded, onTap: _abrirPasarListaRapido),
    ]);
  }

  Widget _feedCard({required String badge, required Color badgeColor, required String title, required String subtitle, required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: badgeColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
              child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
            ),
            const SizedBox(height: 8),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF0F172A))),
            const SizedBox(height: 3),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF334155))));

  Widget _pill({required IconData icon, required String text, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(999)),
        child: Row(children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 4), Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
      ),
    );
  }

  Widget _buildErrorView() => Center(child: Text(_errorMsg ?? "Error"));
  String _weekdayEs(int w) => ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"][w - 1];
  String _monthEs(int m) => ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"][m - 1];
}

class _ActionItem {
  final String title, subtitle; final IconData icon; final Color tint; final VoidCallback onTap;
  _ActionItem({required this.title, required this.subtitle, required this.icon, required this.tint, required this.onTap});
}