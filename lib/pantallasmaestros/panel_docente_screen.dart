import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

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
      _nombreProfesor = nombre.split(' ')[0];
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
      try {
        final stats = await ApiService.getProfesorStats(profesorId);
        _totalGrupos = stats['grupos'] ?? 0;
        _totalAlumnos = stats['alumnos'] ?? 0;
      } catch (e) {
        _totalGrupos = 0;
        _totalAlumnos = 0;
      }

      final gruposAsignados = await ApiService.getGrupos();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (gruposAsignados.isNotEmpty) {
            final primeraClase = gruposAsignados.first;
            _claseEnCurso = primeraClase.materia;
            _subClaseEnCurso = "Grupo ${primeraClase.nombre}";
          } else {
            _claseEnCurso = "Sin Clases Asignadas";
            _subClaseEnCurso = "Consulta Mis Grupos";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = "Error al conectar con el servidor.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryBlue))
            : _errorMsg != null
            ? _buildErrorView()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 25),
                    _buildQuickStats(),
                    const SizedBox(height: 25),
                    const Text(
                      "Actividad de hoy",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _infoCard(
                      title: "Vacio",
                      content: _claseEnCurso,
                      subContent: _subClaseEnCurso,
                      icon: Icons.school_rounded,
                      color: primaryBlue,
                    ),
                    const SizedBox(height: 15),
                    _infoCard(
                      title: "Vacio",
                      content: "Vacio",
                      subContent: "Sin información adicional",
                      icon: Icons.assignment_late_rounded,
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "¡Hola, $_nombreProfesor! ",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: darkBlue,
              ),
            ),
            const Text(
              "Bienvenido a tu panel de control",
              style: TextStyle(color: Colors.blueGrey, fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard("$_totalGrupos", "Grupos", Icons.groups_rounded),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _statCard(
            "$_totalAlumnos",
            "Alumnos",
            Icons.person_search_rounded,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String number, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryBlue.withOpacity(0.6), size: 28),
          const SizedBox(height: 12),
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String content,
    required String subContent,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subContent,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: Colors.red[200]),
            const SizedBox(height: 20),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: StadiumBorder(),
              ),
              onPressed: () => _cargarEstadisticas(_profesorId),
              child: const Text(
                "Reintentar conexión",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
