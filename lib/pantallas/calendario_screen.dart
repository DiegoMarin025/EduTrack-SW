import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// -------------------------
// Modelo de Datos: Evento
// -------------------------
class Evento {
  final String titulo;
  final String tipo;
  final Color color;
  final IconData icon;
  final DateTime fechaInicio;
  final DateTime fechaFin;

  Evento({
    required this.titulo,
    required this.tipo,
    required this.color,
    required this.icon,
    required this.fechaInicio,
    required this.fechaFin,
  });
}

// -------------------------
// Pantalla: CalendarioScreen
// -------------------------
class CalendarioScreen extends StatefulWidget {
  // CORRECCIÓN: Agregamos el parámetro onNavigate
  final void Function(int)? onNavigate;

  const CalendarioScreen({super.key, this.onNavigate});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final Color purpleDeep = const Color(0xFF6A0DAD);
  final Color purpleMedium = const Color(0xFF9B4F96);
  final Color purpleLight = const Color(0xFFE8D9FF);

  // -------------------------
  // Eventos de ejemplo
  // -------------------------
  final List<Evento> _todosLosEventos = [
    Evento(
      titulo: "Fin de Cuatrimestre Sep-Dic",
      tipo: "Cierre",
      color: Colors.orange,
      icon: Icons.flag_rounded,
      fechaInicio: DateTime(2025, 12, 13),
      fechaFin: DateTime(2025, 12, 13),
    ),
    Evento(
      titulo: "Vacaciones de Invierno",
      tipo: "Vacaciones",
      color: Colors.blue,
      icon: Icons.beach_access_rounded,
      fechaInicio: DateTime(2025, 12, 16),
      fechaFin: DateTime(2026, 1, 3),
    ),
    Evento(
      titulo: "Inicio Cuatrimestre Ene-Abr",
      tipo: "Inicio",
      color: Colors.green,
      icon: Icons.school_rounded,
      fechaInicio: DateTime(2026, 1, 6),
      fechaFin: DateTime(2026, 1, 6),
    ),
    Evento(
      titulo: "Suspensión de Labores",
      tipo: "Día Inhábil",
      color: Colors.red,
      icon: Icons.block_rounded,
      fechaInicio: DateTime(2026, 2, 3),
      fechaFin: DateTime(2026, 2, 3),
    ),
    Evento(
      titulo: "1ra Evaluación Parcial",
      tipo: "Examen",
      color: Colors.purple,
      icon: Icons.assignment_turned_in_rounded,
      fechaInicio: DateTime(2026, 2, 10),
      fechaFin: DateTime(2026, 2, 14),
    ),
  ];

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _focusedDay = _selectedDay;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // -------------------------
  // Funciones de eventos
  // -------------------------
  List<Evento> _getEventsForDay(DateTime day) {
    return _todosLosEventos.where((evento) {
      final start = DateTime(
        evento.fechaInicio.year,
        evento.fechaInicio.month,
        evento.fechaInicio.day,
      );
      final end = DateTime(
        evento.fechaFin.year,
        evento.fechaFin.month,
        evento.fechaFin.day,
      );
      final q = DateTime(day.year, day.month, day.day);

      return (q.isAtSameMomentAs(start) || q.isAfter(start)) &&
          (q.isAtSameMomentAs(end) || q.isBefore(end));
    }).toList();
  }

  List<Evento> _getEventsForAgenda() {
    final copy = List<Evento>.from(_todosLosEventos);
    copy.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    return copy;
  }

  // -------------------------
  // UI Helpers
  // -------------------------
  Widget _buildEventMarker(DateTime date, List<Evento> events) {
    final markers = events.take(3).map((e) => e.color).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: markers
          .map(
            (c) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAgendaCard(Evento evento, int index) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [evento.color.withOpacity(0.12), Colors.white],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: evento.color.withOpacity(0.18)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: evento.color,
            child: Icon(evento.icon, color: Colors.white),
          ),
          title: Text(
            evento.titulo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(evento.tipo),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }

  // -------------------------
  // Build
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final eventosAgenda = _getEventsForAgenda();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FB),

      // -------------------------
      // 🔥 SOLUCIÓN AL OVERFLOW
      // -------------------------
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------- Vista rápida ----------
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [purpleLight, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: purpleMedium),
                          const SizedBox(width: 10),
                          Text(
                            "${eventosAgenda.length} próximos eventos",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ---------- Calendario ----------
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: TableCalendar<Evento>(
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2027, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          eventLoader: _getEventsForDay,
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            titleTextStyle: TextStyle(
                              color: purpleDeep,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isEmpty)
                                return const SizedBox.shrink();
                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: _buildEventMarker(date, events),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      "Próximos eventos",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: purpleDeep,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ---------- Lista Agenda ----------
                    ...eventosAgenda
                        .asMap()
                        .entries
                        .map((e) => _buildAgendaCard(e.value, e.key))
                        .toList(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: purpleDeep,
        child: const Icon(Icons.add),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Función para agregar eventos próximamente"),
            ),
          );
        },
      ),
    );
  }
}
