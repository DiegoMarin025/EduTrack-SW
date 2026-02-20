import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importar SharedPreferences
import '../services/api_service.dart'; // Importar ApiService

class Solution2Soporte extends StatefulWidget {
  final bool needsContact;
  const Solution2Soporte({super.key, this.needsContact = true});

  @override
  _Solution2SoporteState createState() => _Solution2SoporteState();
}

class _Solution2SoporteState extends State<Solution2Soporte> {
  bool aceptaInfo = false;
  final TextEditingController detallesController = TextEditingController();

  // Variables para el envío de datos
  bool _isSending = false;
  int _usuarioId = 0;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // Cargar datos del usuario para el reporte
  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usuarioId = prefs.getInt('saved_id') ?? 0;
      _userEmail =
          prefs.getString('saved_username') ?? 'usuario_anonimo@colegio.com';
    });
  }

  // Función para enviar el reporte al backend
  Future<void> _enviarReporte() async {
    setState(() {
      _isSending = true;
    });

    try {
      // Especificamos que es un problema de conexión
      final mensajeFinal =
          "TIPO: Error de Conexión.\nDETALLES: ${detallesController.text}";

      await ApiService.enviarReporteSoporte(
        _usuarioId,
        _userEmail,
        mensajeFinal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reporte enviado! Revisaremos la conectividad.'),
            backgroundColor: Colors.green,
          ),
        );
        detallesController.clear();
        setState(() {
          aceptaInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayuda de Conexión"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solución para: Error de conexión',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pasos para resolver el problema:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 20),
            const Text('1. Verifica tu conexión a WiFi o datos móviles'),
            const Text('2. Reinicia el router/módem'),
            const Text('3. Actualiza la aplicación'),
            const Text('4. Verifica la configuración de red'),
            const SizedBox(height: 20),

            // ÁREA DE FORMULARIO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PASO 1: Diagnóstico',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Permite que soporte técnico analice tus logs de conexión.',
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.deepPurple,
                    title: const Text(
                      'Acepto compartir información técnica de mi red (Obligatorio)',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: aceptaInfo,
                    onChanged: (val) =>
                        setState(() => aceptaInfo = val ?? false),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Text(
                    'PASO 2: Detalles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Describe cuándo ocurre el error:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detallesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Ej: Se desconecta al entrar a calificaciones...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BOTONES
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade400),
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (aceptaInfo &&
                                  detallesController.text.isNotEmpty &&
                                  !_isSending)
                              ? _enviarReporte
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('ENVIAR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (widget.needsContact) ...[
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Soporte Técnico Directo:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 1,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.email_outlined,
                        color: Colors.deepPurple,
                      ),
                      title: const Text('redes@colegio.com'),
                      subtitle: const Text('Reportar fallas de red'),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(
                          'redes@colegio.com',
                          'Correo copiado',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
