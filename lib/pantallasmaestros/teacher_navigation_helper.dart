import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
// Borra el "as screen" y pon el "hide" que es más fácil:
import 'pasar_lista_screen.dart' hide Grupo, Alumno;

class TeacherNavigationHelper {
  static Future<void> openQuickAttendance({
    required BuildContext context,
    required dynamic profesorId,
  }) async {
    if (profesorId == 0 || profesorId == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontró el profesor.")),
      );
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('grupos')
          .where('profesorId', isEqualTo: profesorId.toString())
          .get();

      final clases = snapshot.docs.map((doc) {
        final data = doc.data();
        return Grupo(
          id: data['id'] ?? doc.id.hashCode,
          nombre: data['nombre'] ?? 'Sin nombre',
          materia: data['materia'] ?? 'Sin materia',
          grupoIdReal: data['grupoIdReal'] ?? 0,
        );
      }).toList();

      if (!context.mounted) return;
      if (clases.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Aún no tienes grupos.")));
        return;
      }

      final Map<int, List<Grupo>> porGrupoReal = {};
      for (final clase in clases) {
        porGrupoReal.putIfAbsent(clase.grupoIdReal, () => []);
        porGrupoReal[clase.grupoIdReal]!.add(clase);
      }

      if (porGrupoReal.length == 1) {
        await _openAttendanceForGroup(context, porGrupoReal.values.first.first);
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
                    "¿A qué grupo vas a pasar lista?",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final bundle = items[index];
                        final rep = bundle.first;
                        return ListTile(
                          leading: const Icon(Icons.groups_rounded),
                          title: Text(
                            rep.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text("${bundle.length} materias"),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await _openAttendanceForGroup(context, rep);
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
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  static Future<void> openAttendanceForRepresentative({
    required BuildContext context,
    required Grupo representative,
  }) async {
    await _openAttendanceForGroup(context, representative);
  }

  static Future<void> _openAttendanceForGroup(
    BuildContext context,
    Grupo representative,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('alumnos')
          .where('grupoId', isEqualTo: representative.grupoIdReal)
          .get();

      final alumnos = snapshot.docs.map((doc) {
        final data = doc.data();
        return Alumno(
          id: data['id'] ?? doc.id.hashCode,
          nombre: data['nombre'] ?? 'Sin nombre',
          correo: data['correo'] ?? '',
        );
      }).toList();

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasarListaScreen( // <-- Debe quedar el nombre normal
            grupo: representative,
            alumnos: alumnos,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
