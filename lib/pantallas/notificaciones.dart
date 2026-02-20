import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Importamos el servicio y los modelos

class NotificationsPage extends StatefulWidget {
  final int usuarioId;

  const NotificationsPage({super.key, required this.usuarioId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Notificacion> _notificaciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    try {
      final lista = await ApiService.getNotificaciones(widget.usuarioId);
      if (mounted) {
        setState(() {
          _notificaciones = lista;
          _loading = false;
        });
      }
    } catch (e) {
      print("Error cargando notificaciones: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notificaciones",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9D4EDD), Color(0xFFEBDDFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _notificaciones.isEmpty
            ? const Center(
                child: Text(
                  "No tienes notificaciones nuevas",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : RefreshIndicator(
                onRefresh: _cargarNotificaciones,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notificaciones.length,
                  itemBuilder: (context, index) {
                    final notif = _notificaciones[index];
                    return _notificationCard(notif);
                  },
                ),
              ),
      ),
    );
  }

  Widget _notificationCard(Notificacion notif) {
    // Lógica para detectar alertas (Reprobado, Baja, Advertencia)
    final bool esAlerta =
        notif.titulo.contains("Alerta") ||
        notif.titulo.contains("Baja") ||
        notif.mensaje.contains("reprobatoria");

    // Colores dinámicos
    final Color backgroundColor = esAlerta
        ? Colors.red.shade50.withOpacity(0.9)
        : (notif.leida
              ? Colors.white.withOpacity(0.7)
              : Colors.white.withOpacity(0.95));

    final Color iconColor = esAlerta ? Colors.red : Colors.deepPurple;
    final IconData iconData = esAlerta
        ? Icons.warning_rounded
        : Icons.notifications;

    // Formato de fecha
    String fechaCorta = notif.fecha.length > 10
        ? notif.fecha.substring(0, 10)
        : notif.fecha;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: esAlerta
            ? Border.all(color: Colors.red, width: 1.5)
            : (!notif.leida
                  ? Border.all(color: Colors.deepPurple, width: 2)
                  : null),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(iconData, size: 20, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notif.titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: esAlerta ? Colors.red[800] : Colors.deepPurple,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notif.leida && !esAlerta)
                const Icon(Icons.circle, size: 12, color: Colors.redAccent),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notif.mensaje,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              fechaCorta,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
