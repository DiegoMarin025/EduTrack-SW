import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pasar_lista_screen.dart';

class TeacherNavigationHelper {
  static Future<void> openQuickAttendance({
    required BuildContext context,
    required int profesorId,
  }) async {
    if (profesorId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontro el profesor.")),
      );
      return;
    }

    try {
      final clases = await ApiService.getGrupos(profesorId: profesorId);

      if (!context.mounted) return;

      if (clases.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Aun no tienes grupos o materias. Ve a Mis Grupos y crea una materia.",
            ),
          ),
        );
        return;
      }

      final Map<int, List<Grupo>> porGrupoReal = {};
      for (final clase in clases) {
        porGrupoReal.putIfAbsent(clase.grupoIdReal, () => []);
        porGrupoReal[clase.grupoIdReal]!.add(clase);
      }

      if (porGrupoReal.length == 1) {
        final representative = porGrupoReal.values.first.first;
        await _openAttendanceForGroup(context, representative);
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (sheetContext) {
          final items = porGrupoReal.values.toList();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "A que grupo vas a pasar lista?",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final bundle = items[index];
                        final representative = bundle.first;
                        final materiasCount = bundle.length;

                        return ListTile(
                          leading: const Icon(Icons.groups_rounded),
                          title: Text(
                            representative.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text("$materiasCount materias"),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await _openAttendanceForGroup(
                              context,
                              representative,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al abrir pasar lista: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> openAttendanceForRepresentative({
    required BuildContext context,
    required Grupo representative,
  }) async {
    try {
      await _openAttendanceForGroup(context, representative);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al abrir pasar lista: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _openAttendanceForGroup(
    BuildContext context,
    Grupo representative,
  ) async {
    final alumnos = await ApiService.getAlumnosRegistrados(representative);

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PasarListaScreen(
          grupo: representative,
          alumnos: alumnos,
        ),
      ),
    );
  }
}
