import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- CONEXIÓN A LA NUBE
import '../services/api_service.dart'; // <--- Usamos el Grupo de aquí
import 'detalle_grupo_screen.dart';
import 'dialog_crear_clase.dart';
import 'teacher_navigation_helper.dart';

class MisGruposScreen extends StatefulWidget {
  const MisGruposScreen({super.key});

  @override
  State<MisGruposScreen> createState() => _MisGruposScreenState();
}

class _MisGruposScreenState extends State<MisGruposScreen> {
  // ✅ Usamos el modelo Grupo oficial de tu proyecto
  List<Grupo> _clases = []; 
  bool _loading = true;
  String _profesorUid = ""; 

  final Color primaryBlue = const Color(0xFF2D63ED);
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF0F172A);
  final Color textSoft = const Color(0xFF64748B);
  final Color border = const Color(0xFFE2E8F0);

  final Set<int> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    String uidGuardado = prefs.getString('saved_uid') ?? "";

    //  MAGIA AUTO-REPARADORA: Si el navegador olvidó el UID, lo buscamos en Firebase usando el correo
    if (uidGuardado.isEmpty) {
      String correo = prefs.getString('saved_username') ?? ""; 
      if (correo.isNotEmpty) {
        try {
          final query = await FirebaseFirestore.instance
              .collection('usuarios')
              .where('email', isEqualTo: correo)
              .get();
          
          if (query.docs.isNotEmpty) {
            uidGuardado = query.docs.first.id; // ¡Atrapamos el UID real!
            await prefs.setString('saved_uid', uidGuardado); // Lo guardamos en Chrome
          }
        } catch (e) {
          debugPrint("Error buscando al maestro: $e");
        }
      }
    }

    setState(() {
      _profesorUid = uidGuardado;
    });

    if (_profesorUid.isNotEmpty) {
      _cargarClasesFirebase();
    } else {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cierra sesión y vuelve a entrar para sincronizar tu cuenta.")),
        );
      }
    }
  }

  // ======================================================
  // 💾 LÓGICA DE FIREBASE (Sustituye a ApiService viejo)
  // ======================================================
  Future<void> _cargarClasesFirebase() async {
    setState(() => _loading = true);
    try {
      // ✅ Buscamos en la colección 'grupos' de la nube
      final snapshot = await FirebaseFirestore.instance
          .collection('grupos')
          .where('profesorId', isEqualTo: _profesorUid)
          .get();

      final gruposFirebase = snapshot.docs.map((doc) {
        final data = doc.data();
        return Grupo(
          id: data['id'] ?? doc.id.hashCode,
          nombre: data['nombre'] ?? 'Sin nombre',
          materia: data['materia'] ?? 'Sin materia',
          grupoIdReal: data['grupoIdReal'] ?? 0,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _clases = gruposFirebase;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint("Error Firebase: $e");
    }
  }

  void _abrirDialogoCrear() {
    if (_profesorUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No se identificó al profesor")),
      );
      return;
    }

    showDialog(
      context: context,
      // ✅ Usamos el hash del UID para el ID numérico si lo necesitas
      builder: (context) => DialogCrearClase(profesorId: _profesorUid.hashCode),
    ).then((_) => _cargarClasesFirebase());
  }

  List<_GrupoBundle> _buildBundles() {
    final Map<int, _GrupoBundle> map = {};

    for (final c in _clases) {
      final key = c.grupoIdReal; 
      map.putIfAbsent(
        key,
        () => _GrupoBundle(grupoIdReal: key, nombreGrupo: c.nombre, items: []),
      );
      map[key]!.items.add(c);
    }

    final list = map.values.toList();
    list.sort((a, b) => a.nombreGrupo.toLowerCase().compareTo(b.nombreGrupo.toLowerCase()));
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
    final width = MediaQuery.of(context).size.width;
    final fabRightInset = width >= 1100 ? 170.0 : (width >= 800 ? 154.0 : 138.0);

    return Scaffold(
      backgroundColor: bgLight,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(right: fabRightInset),
        child: FloatingActionButton.extended(
          onPressed: _abrirDialogoCrear,
          label: const Text("Grupo o materia"),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: primaryBlue))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: ListView(
                  children: [
                    Text("Tu salon y tus materias", style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text("¡Administra tu lista de alumnos y asistencia!", style: TextStyle(color: textSoft, fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 14),
                    if (bundles.isEmpty) ...[
                      _OnboardingEmpty(primaryBlue: primaryBlue, border: border, textDark: textDark, textSoft: textSoft, onCreate: _abrirDialogoCrear),
                      const SizedBox(height: 12),
                      _TipCard(border: border, textSoft: textSoft, textDark: textDark),
                    ] else ...[
                      _TodayCard(primaryBlue: primaryBlue, border: border, textDark: textDark, textSoft: textSoft),
                      const SizedBox(height: 14),
                      Text("Mis grupos", style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      for (final bundle in bundles) ...[
                        _GroupCard(
                          primaryBlue: primaryBlue,
                          border: border,
                          textDark: textDark,
                          textSoft: textSoft,
                          bundle: bundle,
                          expanded: _expandedGroups.contains(bundle.grupoIdReal),
                          onToggleExpand: () => _toggleExpand(bundle.grupoIdReal),
                          onOpenAlumnos: () {
                            final representative = bundle.items.first;
                            Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleGrupoScreen(grupo: representative)));
                          },
                          onPasarLista: () {
                            final representative = bundle.items.first;
                            TeacherNavigationHelper.openAttendanceForRepresentative(context: context, representative: representative);
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

// ✅ MANTENEMOS TUS COMPONENTES DE UI EXACTAMENTE IGUALES ABAJO
class _OnboardingEmpty extends StatelessWidget {
  final Color primaryBlue, border, textDark, textSoft;
  final VoidCallback onCreate;
  const _OnboardingEmpty({required this.primaryBlue, required this.border, required this.textDark, required this.textSoft, required this.onCreate});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: primaryBlue.withOpacity(0.10), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.school_rounded, color: primaryBlue)),
          const SizedBox(width: 12),
          Expanded(child: Text("Aún no tienes grupos", style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 10),
        Text("Crea tu primer grupo, ponle nombre y agrega una materia.", style: TextStyle(color: textSoft, fontSize: 13.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text("Crear mi primer grupo", style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

class _TipCard extends StatelessWidget {
  final Color border, textSoft, textDark;
  const _TipCard({required this.border, required this.textSoft, required this.textDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(child: Text("Tip: Agrega el grupo que se te fué asigando.", style: TextStyle(color: textSoft, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final Color primaryBlue, border, textDark, textSoft;
  const _TodayCard({required this.primaryBlue, required this.border, required this.textDark, required this.textSoft});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: primaryBlue.withOpacity(0.10), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.today_rounded, color: primaryBlue)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Hoy • ${now.day}/${now.month}/${now.year}", style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 14.5)),
          const SizedBox(height: 4),
          Text("Asistencia: pendiente", style: TextStyle(color: textSoft, fontWeight: FontWeight.w600, fontSize: 12.8)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)), child: Text("Pendiente", style: TextStyle(color: textSoft, fontWeight: FontWeight.w800, fontSize: 12))),
      ]),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Color primaryBlue, border, textDark, textSoft;
  final _GrupoBundle bundle;
  final bool expanded;
  final VoidCallback onToggleExpand, onOpenAlumnos, onPasarLista;
  const _GroupCard({required this.primaryBlue, required this.border, required this.textDark, required this.textSoft, required this.bundle, required this.expanded, required this.onToggleExpand, required this.onOpenAlumnos, required this.onPasarLista});
  @override
  Widget build(BuildContext context) {
    final materias = bundle.items.map((e) => e.materia).toList();
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border), borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onToggleExpand,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(color: primaryBlue.withOpacity(0.10), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.groups_rounded, color: primaryBlue)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bundle.nombreGrupo, style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text("${materias.length} materias", style: TextStyle(color: textSoft, fontWeight: FontWeight.w600, fontSize: 13)),
              ])),
              Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.grey[500]),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: onPasarLista, style: OutlinedButton.styleFrom(side: BorderSide(color: border), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 10)), icon: const Icon(Icons.checklist_rounded, size: 18), label: const Text("Pasar lista", style: TextStyle(fontWeight: FontWeight.w800)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(onPressed: onOpenAlumnos, style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 10)), icon: const Icon(Icons.people_alt_rounded, size: 18), label: const Text("Alumnos", style: TextStyle(fontWeight: FontWeight.w800)))),
          ]),
        ),
        if (expanded) ...[
          Container(height: 1, color: border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Materias", style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: materias.map((m) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)), child: Text(m, style: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 12.5)))).toList()),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _GrupoBundle {
  final int grupoIdReal;
  final String nombreGrupo;
  final List<Grupo> items;
  _GrupoBundle({required this.grupoIdReal, required this.nombreGrupo, required this.items});
}