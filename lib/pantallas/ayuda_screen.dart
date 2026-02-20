import 'package:flutter/material.dart';
import 'package:app_calificaciones/soporte/solucion1_soporte.dart';
import 'package:app_calificaciones/soporte/solucion2_soporte.dart';
import 'package:app_calificaciones/soporte/solucion3_soporte.dart';
import 'package:app_calificaciones/soporte/solucion4_soporte.dart';
import 'package:app_calificaciones/soporte/solucion5_soporte.dart';

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  final List<Map<String, dynamic>> problemas = const [
    {'titulo': 'No puedo iniciar sesión', 'archivo': Solution1Soporte()},
    {'titulo': 'Error de conexión', 'archivo': Solution2Soporte()},
    {'titulo': 'La aplicación se cierra', 'archivo': Solution3Soporte()},
    {'titulo': 'No cargan las calificaciones', 'archivo': Solution4Soporte()},
    {'titulo': 'Error al subir archivos', 'archivo': Solution5Soporte()},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Necesitas ayuda?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige un problema para ver la solución o contacta al final de la página.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Lista de botones que navegan a las páginas de solución
            Expanded(
              child: ListView.builder(
                itemCount: problemas.length,
                itemBuilder: (context, index) {
                  final problema = problemas[index];
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => problema['archivo']),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            problema['titulo'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            // Footer con contactos
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contactos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(
                      Icons.email_outlined,
                      color: Colors.deepPurple.shade800,
                    ),
                    title: const Text('Correo del colegio'),
                    subtitle: const Text('soporte@colegio.com'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.phone_android,
                      color: Colors.deepPurple.shade800,
                    ),
                    title: const Text('Teléfono del colegio'),
                    subtitle: const Text('+52 55 1234 5678'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
