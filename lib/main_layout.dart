import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'pantallas/ayuda_screen.dart';
import 'pantallas/historial_academico_screen.dart';
import 'pantallas/notificaciones.dart';
import 'pantallas/tutor/tutor_communication_screen.dart';
import 'pantallas/tutor/tutor_dashboard.dart';
import 'pantallas/tutor/tutor_demo_data.dart';

class MainLayout extends StatefulWidget {
  final String username;
  final int usuarioId;

  const MainLayout({
    super.key,
    required this.username,
    required this.usuarioId,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  int _linkedStudentId = 0;
  String _nombreDisplay = '';
  String _correoDisplay = '';
  String _rolDisplay = '';

  @override
  void initState() {
    super.initState();
    _nombreDisplay = widget.username;
    _cargarDatosUsuario();
    _cargarIndiceGuardado();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _correoDisplay =
          prefs.getString('saved_username') ?? 'correo@ejemplo.com';
      _rolDisplay = prefs.getString('saved_userType') ?? 'Alumno';
      _linkedStudentId = prefs.getInt('saved_linked_student_id') ?? 0;
      if (_nombreDisplay == 'Alumno' || _nombreDisplay.isEmpty) {
        _nombreDisplay = _correoDisplay.split('@')[0];
      }
    });
  }

  Future<void> _cargarIndiceGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('selectedIndex') ?? 0;
    setState(() {
      _selectedIndex = savedIndex.clamp(0, 3);
    });
  }

  List<Widget> get _widgetOptions => <Widget>[
    TutorDashboard(
      userId: widget.usuarioId,
      username: _displayName,
    ),
    HistorialAcademicoScreen(
      alumnoId: _linkedStudentId > 0 ? _linkedStudentId : widget.usuarioId,
      onNavigate: _onSelectItem,
    ),
    TutorCommunicationScreen(
      initialSnapshot: buildTutorDemoData(tutorName: _displayName),
      userId: widget.usuarioId,
      tutorName: _displayName,
    ),
    const AyudaScreen(),
  ];

  List<String> get _screenTitles => [
    _isTutor ? 'Panel del Tutor' : 'Mi Desempeno',
    'Historial Academico',
    'Seguimiento al maestro',
    'Ayuda y Soporte',
  ];

  String get _displayName =>
      _nombreDisplay.isNotEmpty ? _nombreDisplay : widget.username;

  bool get _isTutor => _rolDisplay.trim().toLowerCase() == 'tutor';

  Future<void> _onSelectItem(int index) async {
    final safeIndex = index.clamp(0, _widgetOptions.length - 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedIndex', safeIndex);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = safeIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationsPage(usuarioId: widget.usuarioId),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildDrawerHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard_rounded,
                      text: _isTutor ? 'Panel del Tutor' : 'Mi Desempeno',
                      index: 0,
                    ),
                    _buildDrawerItem(
                      icon: Icons.school_rounded,
                      text: 'Historial Academico',
                      index: 1,
                    ),
                    _buildDrawerItem(
                      icon: Icons.forum_outlined,
                      text: 'Seguimiento al maestro',
                      index: 2,
                    ),
                    const Divider(
                      color: Colors.grey,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildDrawerItem(
                      icon: Icons.help_outline_rounded,
                      text: 'Necesitas ayuda?',
                      index: 3,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Cerrar sesion',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF9575CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Text(
              _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'A',
              style: const TextStyle(
                fontSize: 30,
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            _displayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _correoDisplay,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _rolDisplay.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                  const Color(0xFF1E3A8A).withValues(alpha: 0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade700,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          _onSelectItem(index);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
