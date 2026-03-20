import 'package:flutter/material.dart';
import 'animated_owl_avatar.dart';

enum TeacherAssistantActionType {
  openDashboard,
  openGroups,
  openGrades,
  openSupport,
  quickAttendance,
}

class TeacherOwlAssistant extends StatefulWidget {
  final int selectedSection;
  final Future<void> Function(TeacherAssistantActionType action) onActionSelected;

  const TeacherOwlAssistant({
    super.key,
    required this.selectedSection,
    required this.onActionSelected,
  });

  @override
  State<TeacherOwlAssistant> createState() => _TeacherOwlAssistantState();
}

class _TeacherOwlAssistantState extends State<TeacherOwlAssistant> {
  bool _sheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final data = _TeacherAssistantContextData.fromSection(
      widget.selectedSection,
    );
    final mood = _sheetOpen ? OwlMood.talking : data.mood;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(right: 20, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _sheetOpen
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(data.hint),
                      constraints: const BoxConstraints(maxWidth: 220),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              data.hint,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.8,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: _openAssistantSheet,
                child: Ink(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2D63ED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Center(
                          child: AnimatedOwlAvatar(size: 74, mood: mood),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            "MVP",
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAssistantSheet() async {
    setState(() => _sheetOpen = true);
    final action = await showModalBottomSheet<TeacherAssistantActionType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TeacherAssistantSheet(
        data: _TeacherAssistantContextData.fromSection(widget.selectedSection),
      ),
    );

    if (mounted) {
      setState(() => _sheetOpen = false);
    }

    if (action != null) {
      await widget.onActionSelected(action);
    }
  }
}

class _TeacherAssistantSheet extends StatefulWidget {
  final _TeacherAssistantContextData data;

  const _TeacherAssistantSheet({required this.data});

  @override
  State<_TeacherAssistantSheet> createState() => _TeacherAssistantSheetState();
}

class _TeacherAssistantSheetState extends State<_TeacherAssistantSheet> {
  late final List<_AssistantMessage> _messages;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _messages = [
      _AssistantMessage.assistant(
        "Soy Buho, tu asistente interactivo del panel docente.",
      ),
      _AssistantMessage.assistant(widget.data.intro),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.84,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF2D63ED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: AnimatedOwlAvatar(
                            size: 46,
                            mood: OwlMood.talking,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.data.title,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.data.subtitle,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? const Color(0xFFDBEAFE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: message.isUser
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: _messages.length,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Acciones rapidas",
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.data.actions
                        .map(
                          (action) => _ActionChipButton(
                            action: action,
                            busy: _processing,
                            onTap: () => _handleActionTap(action),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Version MVP: respuestas guiadas y navegacion directa.",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleActionTap(_TeacherAssistantAction action) async {
    if (_processing) return;

    setState(() {
      _processing = true;
      _messages.add(_AssistantMessage.user(action.userText));
    });

    await Future<void>.delayed(const Duration(milliseconds: 260));

    if (!mounted) return;

    setState(() {
      _messages.add(_AssistantMessage.assistant(action.assistantReply));
    });

    await Future<void>.delayed(const Duration(milliseconds: 420));

    if (!mounted) return;

    Navigator.of(context).pop(action.type);
  }
}

class _ActionChipButton extends StatelessWidget {
  final _TeacherAssistantAction action;
  final bool busy;
  final VoidCallback onTap;

  const _ActionChipButton({
    required this.action,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: busy ? null : onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: busy ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: busy ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 18,
              color: busy ? const Color(0xFF94A3B8) : const Color(0xFF1D4ED8),
            ),
            const SizedBox(width: 8),
            Text(
              action.label,
              style: TextStyle(
                color: busy ? const Color(0xFF94A3B8) : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w800,
                fontSize: 12.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherAssistantContextData {
  final String title;
  final String subtitle;
  final String intro;
  final String hint;
  final OwlMood mood;
  final List<_TeacherAssistantAction> actions;

  const _TeacherAssistantContextData({
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.hint,
    required this.mood,
    required this.actions,
  });

  factory _TeacherAssistantContextData.fromSection(int section) {
    switch (section) {
      case 1:
        return _TeacherAssistantContextData(
          title: "Buho en Mis Grupos",
          subtitle: "Te ayudo a volver al panel, pasar lista o abrir soporte.",
          intro:
              "Estas en Mis Grupos. Desde aqui normalmente buscas alumnos, pasas lista o subes calificaciones.",
          hint: "Te llevo a tus grupos y alumnos",
          mood: OwlMood.helpful,
          actions: const [
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.quickAttendance,
              label: "Pasar lista",
              icon: Icons.checklist_rounded,
              userText: "Quiero pasar lista ahora.",
              assistantReply: "Perfecto. Te abro el flujo de asistencia.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openDashboard,
              label: "Ir al panel",
              icon: Icons.dashboard_rounded,
              userText: "Llevame al panel docente.",
              assistantReply: "Voy de regreso al panel principal.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openGrades,
              label: "Calificaciones",
              icon: Icons.grade_rounded,
              userText: "Necesito subir calificaciones.",
              assistantReply: "Abro la captura de calificaciones.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openSupport,
              label: "Soporte",
              icon: Icons.support_agent_rounded,
              userText: "Quiero ir a ayuda y soporte.",
              assistantReply: "Listo. Te llevo al centro de ayuda.",
            ),
          ],
        );
      case 2:
        return _TeacherAssistantContextData(
          title: "Buho en Calificaciones",
          subtitle:
              "Si quieres, te regreso al panel o abro materias y asistencia.",
          intro:
              "Estas capturando calificaciones. Puedo cambiarte rapido a materias, asistencia o soporte si lo necesitas.",
          hint: "Subimos calificaciones o cambiamos de modulo?",
          mood: OwlMood.happy,
          actions: const [
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openGroups,
              label: "Abrir materias",
              icon: Icons.class_rounded,
              userText: "Quiero abrir materias.",
              assistantReply: "Te llevo a Mis Grupos.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.quickAttendance,
              label: "Pasar lista",
              icon: Icons.how_to_reg_rounded,
              userText: "Mejor voy a pasar lista.",
              assistantReply: "Cambio al flujo de asistencia.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openDashboard,
              label: "Panel docente",
              icon: Icons.space_dashboard_rounded,
              userText: "Regresemos al panel docente.",
              assistantReply: "Claro. Regresamos al panel principal.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openSupport,
              label: "Soporte",
              icon: Icons.help_outline_rounded,
              userText: "Necesito ayuda tecnica.",
              assistantReply: "Abro ayuda y soporte.",
            ),
          ],
        );
      case 3:
        return _TeacherAssistantContextData(
          title: "Buho en Planeacion",
          subtitle:
              "Puedo llevarte al panel, materias, calificaciones o soporte si cambias de tarea.",
          intro:
              "Estas organizando tu planeacion docente. Desde aqui defines tema, actividad, fecha y materia para cada clase.",
          hint: "Listo para organizar tu proxima clase",
          mood: OwlMood.helpful,
          actions: const [
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openDashboard,
              label: "Volver al panel",
              icon: Icons.dashboard_customize_rounded,
              userText: "Quiero volver al panel.",
              assistantReply: "Te llevo al panel docente.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openGroups,
              label: "Ir a materias",
              icon: Icons.menu_book_rounded,
              userText: "Necesito revisar mis materias.",
              assistantReply: "Perfecto. Te abro Mis Grupos.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openGrades,
              label: "Calificaciones",
              icon: Icons.school_rounded,
              userText: "Necesito subir calificaciones.",
              assistantReply: "Abro el modulo de calificaciones.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openSupport,
              label: "Soporte",
              icon: Icons.support_agent_rounded,
              userText: "Quiero abrir ayuda y soporte.",
              assistantReply: "Listo. Te llevo al centro de ayuda.",
            ),
          ],
        );
      case 4:
        return _TeacherAssistantContextData(
          title: "Buho en Soporte",
          subtitle:
              "Puedo llevarte otra vez al panel, materias, calificaciones o asistencia.",
          intro:
              "Estoy en modo alerta por si algo falla. Si ya terminaste aqui, te regreso al modulo que necesites.",
          hint: "Estoy atento si algo falla",
          mood: OwlMood.alert,
          actions: const [
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openDashboard,
              label: "Volver al panel",
              icon: Icons.dashboard_customize_rounded,
              userText: "Quiero volver al panel.",
              assistantReply: "Te llevo al panel docente.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openGroups,
              label: "Ir a materias",
              icon: Icons.menu_book_rounded,
              userText: "Llevame a materias.",
              assistantReply: "Perfecto. Te abro Mis Grupos.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openGrades,
              label: "Ir a calificaciones",
              icon: Icons.school_rounded,
              userText: "Necesito subir calificaciones.",
              assistantReply: "Abro el modulo de calificaciones.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.quickAttendance,
              label: "Pasar lista",
              icon: Icons.assignment_turned_in_rounded,
              userText: "Vamos a pasar lista.",
              assistantReply: "Te abro asistencia ahora mismo.",
            ),
          ],
        );
      case 0:
      default:
        return _TeacherAssistantContextData(
          title: "Buho en Panel Docente",
          subtitle:
              "Te ayudo a moverte rapido entre asistencia, materias, calificaciones y soporte.",
          intro:
              "Estas en el panel principal. Lo mas util desde aqui suele ser pasar lista, revisar materias o subir calificaciones.",
          hint: "Quieres pasar lista ahora?",
          mood: OwlMood.helpful,
          actions: const [
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.quickAttendance,
              label: "Pasar lista",
              icon: Icons.check_circle_outline_rounded,
              userText: "Ayudame a pasar lista.",
              assistantReply: "Vamos a abrir la asistencia de tus grupos.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openGroups,
              label: "Abrir materias",
              icon: Icons.class_rounded,
              userText: "Llevame a materias.",
              assistantReply: "Voy a Mis Grupos para ver materias y alumnos.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openGrades,
              label: "Calificaciones",
              icon: Icons.grade_rounded,
              userText: "Quiero subir calificaciones.",
              assistantReply: "Abro el modulo de calificaciones.",
            ),
            _TeacherAssistantAction(
              type: TeacherAssistantActionType.openSupport,
              label: "Soporte",
              icon: Icons.support_agent_rounded,
              userText: "Tengo un problema tecnico.",
              assistantReply: "Listo. Te llevo a ayuda y soporte.",
            ),
          ],
        );
    }
  }
}

class _TeacherAssistantAction {
  final TeacherAssistantActionType type;
  final String label;
  final IconData icon;
  final String userText;
  final String assistantReply;

  const _TeacherAssistantAction({
    required this.type,
    required this.label,
    required this.icon,
    required this.userText,
    required this.assistantReply,
  });
}

class _AssistantMessage {
  final String text;
  final bool isUser;

  const _AssistantMessage._({required this.text, required this.isUser});

  factory _AssistantMessage.assistant(String text) {
    return _AssistantMessage._(text: text, isUser: false);
  }

  factory _AssistantMessage.user(String text) {
    return _AssistantMessage._(text: text, isUser: true);
  }
}
