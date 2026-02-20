import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importar SharedPreferences
import '../services/api_service.dart'; // Importar ApiService

class Solution5Soporte extends StatefulWidget {
  final bool needsContact;
  const Solution5Soporte({super.key, this.needsContact = true});

  @override
  _Solution5SoporteState createState() => _Solution5SoporteState();
}

class _Solution5SoporteState extends State<Solution5Soporte> {
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
      // Especificamos el tipo de error
      final mensajeFinal =
          "TIPO: Error Subida de Archivos.\nDETALLES: ${detallesController.text}";

      await ApiService.enviarReporteSoporte(
        _usuarioId,
        _userEmail,
        mensajeFinal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Reporte enviado! Revisaremos el servidor de archivos.',
            ),
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
        title: const Text("Ayuda con Archivos"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solución para: Error al subir archivos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pasos para resolver el problema:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Botón Volver a Inicio
            const SizedBox(height: 20),
            const Text('1. Verifica el tamaño del archivo (máximo 10MB)'),
            const Text(
              '2. Asegúrate de que el formato sea compatible (PDF, DOC, JPG, PNG)',
            ),
            const Text('3. Comprueba tu conexión a internet'),
            const Text('4. Intenta con un nombre de archivo más corto'),
            const Text('5. Reinicia la aplicación y vuelve a intentarlo'),

            const SizedBox(height: 20),

            const Text(
              'Formatos aceptados:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('• Documentos: PDF, DOC, DOCX'),
                  Text('• Imágenes: JPG, JPEG, PNG'),
                  Text('• Presentaciones: PPT, PPTX'),
                  Text(
                    '• Tamaño máximo: 10MB por archivo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

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
                    'Para ayudarte, necesitamos saber qué archivo está fallando.',
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.deepPurple,
                    title: const Text(
                      'Acepto compartir detalles del archivo para diagnóstico (Obligatorio)',
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
                  const Text('Describe el error o nombre del archivo:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detallesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Ej: Al subir la tarea de historia "Ensayo.pdf" se queda cargando...',
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
                'Soporte Técnico:',
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
                      subtitle: const Text('Reportar problemas de plataforma'),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(
                          'soporte@colegio.com',
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

  // Mantenemos tu método original por compatibilidad
  void _showContactDialog(BuildContext context) {
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
