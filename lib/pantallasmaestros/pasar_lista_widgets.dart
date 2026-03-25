import 'package:flutter/material.dart';
import '../services/api_service.dart'; // <--- Para que reconozca a Grupo y Alumno
import '../services/asistencia_service.dart'; // <--- Para que reconozca los estados (Presente/Ausente)


const Color pasarListaPrimaryBlue = Color(0xFF2D63ED);
const Color pasarListaBgLight = Color(0xFFF8FAFC);
const Color _borderColor = Color(0xFFE2E8F0);

class PasarListaScaffoldFrame extends StatelessWidget {
  final Grupo grupo;
  final String fechaTexto;
  final int presentes;
  final int ausentes;
  final int retardos;
  final bool saving;
  final Future<void> Function() onSelectDate;
  final ValueChanged<EstadoAsistencia> onMarkAll;
  final Future<void> Function() onAddStudent;
  final VoidCallback onOpenHistory;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;
  final Widget body;
  final VoidCallback? onExport; // <--- 🟢 Pieza clave 1

  const PasarListaScaffoldFrame({
    super.key,
    required this.grupo,
    required this.fechaTexto,
    required this.presentes,
    required this.ausentes,
    required this.retardos,
    required this.saving,
    required this.onSelectDate,
    required this.onMarkAll,
    required this.onAddStudent,
    required this.onOpenHistory,
    required this.onCancel,
    required this.onSave,
    required this.body,
    this.onExport, // <--- 🟢 Pieza clave 2
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Tu color pasarListaBgLight
      appBar: _PasarListaAppBar(
        grupo: grupo,
        onAddStudent: onAddStudent,
        onOpenHistory: onOpenHistory,
        onExport: onExport, // <--- 🟢 Aquí se lo pasamos a la barra
      ),
      bottomNavigationBar: _PasarListaBottomBar(
        saving: saving,
        onCancel: onCancel,
        onSave: onSave,
      ),
      body: Column(
        children: [
          _PasarListaHeader(
            grupo: grupo,
            fechaTexto: fechaTexto,
            presentes: presentes,
            ausentes: ausentes,
            retardos: retardos,
            onSelectDate: onSelectDate,
            onMarkAll: onMarkAll,
            onAddStudent: onAddStudent,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class EditarNotaSheet extends StatelessWidget {
  final Alumno alumno;
  final TextEditingController controller;

  const EditarNotaSheet({
    super.key,
    required this.alumno,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nota para ${alumno.nombre} | ID ${alumno.id}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Escribe una nota',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Guardar nota'),
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrarAlumnoDialog extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController correoController;
  final Future<void> Function() onSave;

  const RegistrarAlumnoDialog({
    super.key,
    required this.nombreController,
    required this.correoController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar alumno'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nombreController,
            decoration: const InputDecoration(labelText: 'Nombre completo'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: correoController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electronico',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: pasarListaPrimaryBlue,
            foregroundColor: Colors.white,
          ),
          onPressed: () => onSave(),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class PasarListaMobileList extends StatelessWidget {
  final List<Alumno> alumnos;
  final Map<int, EstadoAsistencia> estados;
  final Map<int, TextEditingController> notas;
  final Future<void> Function(Alumno alumno) onEditNota;
  final void Function(int alumnoId, EstadoAsistencia estado) onSelectEstado;

  const PasarListaMobileList({
    super.key,
    required this.alumnos,
    required this.estados,
    required this.notas,
    required this.onEditNota,
    required this.onSelectEstado,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alumnos.length,
      itemBuilder: (context, index) {
        final alumno = alumnos[index];

        return _MobileAlumnoCard(
          alumno: alumno,
          index: index,
          estadoSeleccionado: estados[alumno.id] ?? EstadoAsistencia.ausente,
          nota: notas[alumno.id]?.text.trim() ?? '',
          onEditNota: () => onEditNota(alumno),
          onSelectEstado: (estado) => onSelectEstado(alumno.id, estado),
        );
      },
    );
  }
}

class PasarListaDesktopTable extends StatelessWidget {
  final List<Alumno> alumnos;
  final Map<int, EstadoAsistencia> estados;
  final Map<int, TextEditingController> notas;
  final void Function(int alumnoId, EstadoAsistencia estado) onSelectEstado;

  const PasarListaDesktopTable({
    super.key,
    required this.alumnos,
    required this.estados,
    required this.notas,
    required this.onSelectEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1100,
            child: Column(
              children: [
                const _DesktopHeaderRow(),
                Expanded(
                  child: ListView.builder(
                    itemCount: alumnos.length,
                    itemBuilder: (context, index) {
                      final alumno = alumnos[index];

                      return _DesktopAlumnoRow(
                        alumno: alumno,
                        index: index,
                        notaController: notas[alumno.id],
                        estadoSeleccionado:
                            estados[alumno.id] ?? EstadoAsistencia.ausente,
                        onSelectEstado: (estado) =>
                            onSelectEstado(alumno.id, estado),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasarListaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Grupo grupo;
  final Future<void> Function() onAddStudent;
  final VoidCallback onOpenHistory;
  final VoidCallback? onExport; // <--- 🟢 Agregamos esta línea

  const _PasarListaAppBar({
    required this.grupo,
    required this.onAddStudent,
    required this.onOpenHistory,
    this.onExport, // <--- 🟢 Y esta otra
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: pasarListaPrimaryBlue, // Mantenemos tu color original
      foregroundColor: Colors.white,
      title: Text(
        'Pasar lista \u2022 ${grupo.nombre}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        // 📊 AQUÍ AGREGAMOS EL BOTÓN DE EXCEL
        if (onExport != null)
          IconButton(
            tooltip: 'Exportar a Excel',
            onPressed: onExport,
            icon: const Icon(Icons.file_download_rounded, color: Colors.greenAccent),
          ),
        IconButton(
          tooltip: 'Registrar alumno',
          onPressed: () => onAddStudent(),
          icon: const Icon(Icons.person_add_alt_1_rounded),
        ),
        IconButton(
          onPressed: onOpenHistory,
          icon: const Icon(Icons.history_rounded),
        ),
      ],
    );
  }
}
class _PasarListaHeader extends StatelessWidget {
  final Grupo grupo;
  final String fechaTexto;
  final int presentes;
  final int ausentes;
  final int retardos;
  final Future<void> Function() onSelectDate;
  final ValueChanged<EstadoAsistencia> onMarkAll;
  final Future<void> Function() onAddStudent;

  const _PasarListaHeader({
    required this.grupo,
    required this.fechaTexto,
    required this.presentes,
    required this.ausentes,
    required this.retardos,
    required this.onSelectDate,
    required this.onMarkAll,
    required this.onAddStudent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            grupo.materia,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelectDate(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _borderColor),
                      color: pasarListaBgLight,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: pasarListaPrimaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Fecha: $fechaTexto',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<EstadoAsistencia>(
                onSelected: onMarkAll,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: EstadoAsistencia.presente,
                    child: Text('Marcar todos: Presente'),
                  ),
                  PopupMenuItem(
                    value: EstadoAsistencia.ausente,
                    child: Text('Marcar todos: Ausente'),
                  ),
                  PopupMenuItem(
                    value: EstadoAsistencia.retardo,
                    child: Text('Marcar todos: Retardo'),
                  ),
                ],
                child: const _HeaderActionIcon(icon: Icons.tune_rounded),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Registrar alumno',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onAddStudent(),
                  child: const _HeaderActionIcon(
                    icon: Icons.person_add_alt_1_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ResumenChip(
                label: 'Presentes: $presentes',
                bg: Color(0xFFDCFCE7),
                fg: Color(0xFF166534),
              ),
              _ResumenChip(
                label: 'Ausentes: $ausentes',
                bg: Color(0xFFFEE2E2),
                fg: Color(0xFF991B1B),
              ),
              _ResumenChip(
                label: 'Retardos: $retardos',
                bg: Color(0xFFFFEDD5),
                fg: Color(0xFF9A3412),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.badge_rounded, color: Color(0xFF1D4ED8), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Comparte el ID del alumno con su tutor para que pueda registrarse y vincular su cuenta.',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasarListaBottomBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  const _PasarListaBottomBar({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onCancel,
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: saving ? null : () => onSave(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pasarListaPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Guardar lista',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionIcon extends StatelessWidget {
  final IconData icon;

  const _HeaderActionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
        color: Colors.white,
      ),
      child: Icon(icon, color: pasarListaPrimaryBlue),
    );
  }
}

class _MobileAlumnoCard extends StatelessWidget {
  final Alumno alumno;
  final int index;
  final EstadoAsistencia estadoSeleccionado;
  final String nota;
  final VoidCallback onEditNota;
  final ValueChanged<EstadoAsistencia> onSelectEstado;

  const _MobileAlumnoCard({
    required this.alumno,
    required this.index,
    required this.estadoSeleccionado,
    required this.nota,
    required this.onEditNota,
    required this.onSelectEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: pasarListaPrimaryBlue.withOpacity(0.10),
                foregroundColor: pasarListaPrimaryBlue,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alumno.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StudentIdChip(alumnoId: alumno.id),
                    const SizedBox(height: 6),
                    Text(
                      alumno.correo,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditNota,
                icon: Icon(
                  nota.isNotEmpty
                      ? Icons.sticky_note_2_rounded
                      : Icons.edit_note_rounded,
                  color: nota.isNotEmpty
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _EstadoToggleButton(
                text: 'P',
                estado: EstadoAsistencia.presente,
                selected: estadoSeleccionado == EstadoAsistencia.presente,
                onTap: onSelectEstado,
              ),
              const SizedBox(width: 8),
              _EstadoToggleButton(
                text: 'A',
                estado: EstadoAsistencia.ausente,
                selected: estadoSeleccionado == EstadoAsistencia.ausente,
                onTap: onSelectEstado,
              ),
              const SizedBox(width: 8),
              _EstadoToggleButton(
                text: 'R',
                estado: EstadoAsistencia.retardo,
                selected: estadoSeleccionado == EstadoAsistencia.retardo,
                onTap: onSelectEstado,
              ),
            ],
          ),
          if (nota.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Text(
                nota,
                style: const TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DesktopHeaderRow extends StatelessWidget {
  const _DesktopHeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _TableHeaderCell('#', width: 55, alignment: Alignment.center),
        _TableHeaderCell('Alumno', width: 250),
        _TableHeaderCell('ID alumno', width: 110, alignment: Alignment.center),
        _TableHeaderCell('Presente', width: 120, alignment: Alignment.center),
        _TableHeaderCell('Ausente', width: 120, alignment: Alignment.center),
        _TableHeaderCell('Retardo', width: 120, alignment: Alignment.center),
        _TableHeaderCell('Nota', width: 315),
      ],
    );
  }
}

class _DesktopAlumnoRow extends StatelessWidget {
  final Alumno alumno;
  final int index;
  final TextEditingController? notaController;
  final EstadoAsistencia estadoSeleccionado;
  final ValueChanged<EstadoAsistencia> onSelectEstado;

  const _DesktopAlumnoRow({
    required this.alumno,
    required this.index,
    required this.notaController,
    required this.estadoSeleccionado,
    required this.onSelectEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TableBodyCell(
          width: 55,
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ),
        _TableBodyCell(
          width: 250,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alumno.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                alumno.correo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        _TableBodyCell(
          width: 110,
          alignment: Alignment.center,
          child: _StudentIdChip(alumnoId: alumno.id, compact: true),
        ),
        _TableBodyCell(
          width: 120,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: _EstadoTableCell(
            text: 'P',
            estado: EstadoAsistencia.presente,
            selected: estadoSeleccionado == EstadoAsistencia.presente,
            onTap: onSelectEstado,
          ),
        ),
        _TableBodyCell(
          width: 120,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: _EstadoTableCell(
            text: 'A',
            estado: EstadoAsistencia.ausente,
            selected: estadoSeleccionado == EstadoAsistencia.ausente,
            onTap: onSelectEstado,
          ),
        ),
        _TableBodyCell(
          width: 120,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: _EstadoTableCell(
            text: 'R',
            estado: EstadoAsistencia.retardo,
            selected: estadoSeleccionado == EstadoAsistencia.retardo,
            onTap: onSelectEstado,
          ),
        ),
        _TableBodyCell(
          width: 315,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: TextField(
            controller: notaController,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Nota opcional',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _EstadoToggleButton extends StatelessWidget {
  final String text;
  final EstadoAsistencia estado;
  final bool selected;
  final ValueChanged<EstadoAsistencia> onTap;

  const _EstadoToggleButton({
    required this.text,
    required this.estado,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _estadoStyles[estado]!;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(estado),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? style.solid : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? style.solid : _borderColor),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoTableCell extends StatelessWidget {
  final String text;
  final EstadoAsistencia estado;
  final bool selected;
  final ValueChanged<EstadoAsistencia> onTap;

  const _EstadoTableCell({
    required this.text,
    required this.estado,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _estadoStyles[estado]!;

    return InkWell(
      onTap: () => onTap(estado),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? style.bg : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? style.border : _borderColor,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? style.text : const Color(0xFF64748B),
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final Alignment alignment;

  const _TableHeaderCell(
    this.text, {
    required this.width,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 48,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}

class _TableBodyCell extends StatelessWidget {
  final Widget child;
  final double width;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  const _TableBodyCell({
    required this.child,
    required this.width,
    this.alignment = Alignment.centerLeft,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 68,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderColor),
      ),
      child: child,
    );
  }
}

class _StudentIdChip extends StatelessWidget {
  final int alumnoId;
  final bool compact;

  const _StudentIdChip({
    required this.alumnoId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        'ID: $alumnoId',
        style: TextStyle(
          color: const Color(0xFF1D4ED8),
          fontWeight: FontWeight.w900,
          fontSize: compact ? 11.5 : 12.2,
        ),
      ),
    );
  }
}

class _ResumenChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _ResumenChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _EstadoStyle {
  final Color solid;
  final Color bg;
  final Color border;
  final Color text;

  const _EstadoStyle({
    required this.solid,
    required this.bg,
    required this.border,
    required this.text,
  });
}

const Map<EstadoAsistencia, _EstadoStyle> _estadoStyles = {
  EstadoAsistencia.presente: _EstadoStyle(
    solid: Color(0xFF16A34A),
    bg: Color(0xFFDCFCE7),
    border: Color(0xFF22C55E),
    text: Color(0xFF166534),
  ),
  EstadoAsistencia.ausente: _EstadoStyle(
    solid: Color(0xFFDC2626),
    bg: Color(0xFFFEE2E2),
    border: Color(0xFFEF4444),
    text: Color(0xFF991B1B),
  ),
  EstadoAsistencia.retardo: _EstadoStyle(
    solid: Color(0xFFEA580C),
    bg: Color(0xFFFFEDD5),
    border: Color(0xFFF97316),
    text: Color(0xFF9A3412),
  ),
};
