import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importar SharedPreferences
import '../services/api_service.dart'; // Asegúrate de que la ruta a tu ApiService sea correcta

class Solution1Soporte extends StatefulWidget {
  final bool needsContact;
  const Solution1Soporte({super.key, this.needsContact = true});

  @override
  _Solution1SoporteState createState() => _Solution1SoporteState();
}

class _Solution1SoporteState extends State<Solution1Soporte> {
  bool aceptaInfo = false;
  final TextEditingController detallesController = TextEditingController();

  // Variables de estado para el envío
  bool _isSending = false;
  int _usuarioId = 0;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // Cargamos ID y Correo del usuario logueado (o guardado en caché)
  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usuarioId = prefs.getInt('saved_id') ?? 0;
      // Si no hay correo guardado, usamos uno genérico o pedimos que lo escriban
      _userEmail =
          prefs.getString('saved_username') ?? 'usuario_anonimo@colegio.com';
    });
  }

  // Función real para enviar datos al Backend
  Future<void> _enviarReporte() async {
    setState(() {
      _isSending = true;
    });

    try {
      // Preparamos el mensaje agregando contexto automático
      final mensajeFinal =
          "TIPO: Problema de Inicio de Sesión.\nDETALLES: ${detallesController.text}";

      await ApiService.enviarReporteSoporte(
        _usuarioId,
        _userEmail,
        mensajeFinal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reporte enviado! El equipo técnico te contactará.'),
            backgroundColor: Colors.green,
          ),
        );
        // Limpiamos el formulario
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
        title: const Text("Ayuda con Acceso"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solución para: No puedo iniciar sesión',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pasos para resolver el problema:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Botón "Volver a inicio"
            const SizedBox(height: 20),
            const Text('1. Verifica tu conexión a internet'),
            const Text('2. Reinicia la aplicación'),
            const Text('3. Restablece tu contraseña'),
            const Text('4. Contacta con soporte técnico'),
            const SizedBox(height: 20),

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
                    'PASO 1: Autorización',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Permite que soporte técnico revise tu cuenta para solucionar el fallo.',
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.deepPurple,
                    title: const Text(
                      'Acepto compartir información técnica para solucionar mi problema (Obligatorio)',
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
                  const Text('Describe qué sucede al intentar entrar:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detallesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Me sale error 404 o pantalla blanca...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BOTONES DE ACCIÓN
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
                          // Solo activa el botón si aceptó el checkbox y escribió algo
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
                              : const Text('ENVIAR REPORTE'),
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
                '¿No puedes esperar? Contáctanos:',
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
                      title: const Text('soporte@colegio.com'),
                      subtitle: const Text('Respuesta en < 24hrs'),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(
                          'soporte@colegio.com',
                          'Correo copiado',
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.phone_android,
                        color: Colors.deepPurple,
                      ),
                      title: const Text('+52 55 1234 5678'),
                      subtitle: const Text('Lunes a Viernes, 9am - 6pm'),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(
                          '+52 55 1234 5678',
                          'Teléfono copiado',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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

  void _showContactDialog(BuildContext context) {
    // Mantenemos tu método original por si quieres usarlo en lugar de las Cards
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacto de Soporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Correo: soporte@colegio.com'),
            SizedBox(height: 8),
            Text('Teléfono: +52 55 1234 5678'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
