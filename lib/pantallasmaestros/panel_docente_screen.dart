import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PanelDocenteScreen extends StatefulWidget {
  const PanelDocenteScreen({super.key});

  @override
  State<PanelDocenteScreen> createState() => _PanelDocenteScreenState();
}

class _PanelDocenteScreenState extends State<PanelDocenteScreen> {
  // Variables de estado
  int _profesorId = 0;
  String _nombreProfesor = "Profesor";

  // Datos Dinámicos
  String _claseEnCurso = "Cargando...";
  String _subClaseEnCurso = "";
  int _totalGrupos = 0;
  int _totalAlumnos = 0;
  bool _isLoading = true;
  String? _errorMsg;

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
      _nombreProfesor = nombre.split(' ')[0]; // Usamos solo el primer nombre
    });

    if (id != 0) {
      await _cargarEstadisticas(id);
    } else {
      setState(() {
        _isLoading = false;
        _errorMsg = "Error: No se encontró ID de usuario logueado (ID=0).";
      });
    }
  }

  Future<void> _cargarEstadisticas(int profesorId) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // 1. Intentamos cargar STATS (Protegido con try-catch interno)
      // Si esto falla (ej. tabla no existe), no bloqueamos toda la pantalla.
      try {
        final stats = await ApiService.getProfesorStats(profesorId);
        _totalGrupos = stats['grupos'] ?? 0;
        _totalAlumnos = stats['alumnos'] ?? 0;
      } catch (e) {
        print(
          "⚠️ Advertencia: No se pudieron cargar stats (se usarán ceros): $e",
        );
        // Valores por defecto para no romper la UI
        _totalGrupos = 0;
        _totalAlumnos = 0;
      }

      // 2. Cargamos GRUPOS (Esto es más importante)
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
      print("Error crítico en PanelDocente: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Si fallan los grupos, ahí sí mostramos error porque es esencial
          _errorMsg =
              "No se pudieron cargar los datos del panel.\nError: $e\n\nRevisa la consola de Node.js para más detalles.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "¡Bienvenido, $_nombreProfesor!",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Panel de Control Docente",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Conectando con servidor..."),
                  ],
                ),
              )
            else if (_errorMsg != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMsg!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _cargarEstadisticas(_profesorId),
                        child: const Text("Reintentar"),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Tarjeta de Clase Actual
                  _infoCard(
                    title: "Clase en curso (Ejemplo)",
                    content: _claseEnCurso,
                    subContent: _subClaseEnCurso,
                    icon: Icons.access_time_filled_rounded,
                    color: Colors.purple,
                  ),

                  const SizedBox(height: 15),

                  // Tarjeta de Pendientes
                  _infoCard(
                    title: "Pendientes",
                    content: "Subir calificaciones",
                    subContent: "Próximo cierre: 15 Oct",
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 15),

                  // Estadísticas rápidas
                  Row(
                    children: [
                      Expanded(child: _statCard("$_totalGrupos", "Grupos")),
                      const SizedBox(width: 15),
                      Expanded(child: _statCard("$_totalAlumnos", "Alumnos")),
                    ],
                  ),
                ],
              ),
          ],
        ),
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subContent,
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String number, String label) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
