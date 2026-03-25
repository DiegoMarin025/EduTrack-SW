import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import '../services/asistencia_service.dart';
import 'pasar_lista_widgets.dart';
import 'historial_asistencias_screen.dart';

class PasarListaScreen extends StatefulWidget {
  final Grupo grupo;
  final List<Alumno> alumnos;

  const PasarListaScreen({
    super.key,
    required this.grupo,
    required this.alumnos,
  });

  @override
  State<PasarListaScreen> createState() => _PasarListaScreenState();
}

class _PasarListaScreenState extends State<PasarListaScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  final Map<int, EstadoAsistencia> _estados = {};
  final Map<int, TextEditingController> _notaControllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  void _inicializarDatos() {
    for (var alumno in widget.alumnos) {
      _estados[alumno.id] = EstadoAsistencia.presente;
      _notaControllers[alumno.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _notaControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ======================================================
  // 📊 EXPORTAR A EXCEL (CSV) - El deseo de Diego
  // ======================================================
  void _exportarAExcel() {
    // Generamos el contenido del archivo
    String csv = "Nombre,Estado,Nota,Fecha\n";
    String fecha = "${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}";
    
    for (var alu in widget.alumnos) {
      String est = _estados[alu.id].toString().split('.').last;
      String nota = _notaControllers[alu.id]?.text ?? "";
      csv += "${alu.nombre},$est,$nota,$fecha\n";
    }

    // Por ahora lo mandamos a consola para confirmar que funciona
    debugPrint("--- REPORTE LISTO ---");
    debugPrint(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📊 Reporte preparado para Excel"),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  // ======================================================
  // 💾 GUARDAR ASISTENCIA 
  // ======================================================
  Future<void> _guardarAsistencia() async {
    setState(() => _saving = true);
    try {
      final docRef = FirebaseFirestore.instance.collection('asistencias').doc();

      int p = _estados.values.where((e) => e == EstadoAsistencia.presente).length;
      int a = _estados.values.where((e) => e == EstadoAsistencia.ausente).length;
      int r = _estados.values.where((e) => e == EstadoAsistencia.retardo).length;

      final detalles = widget.alumnos.map((alumno) => {
        'alumnoId': alumno.id,
        'nombreAlumno': alumno.nombre,
        'estado': _estados[alumno.id].toString().split('.').last,
        'nota': _notaControllers[alumno.id]?.text.trim() ?? '',
      }).toList();

      await docRef.set({
        'fecha': Timestamp.fromDate(_fechaSeleccionada),
        'materia': widget.grupo.materia,
        'grupoNombre': widget.grupo.nombre,
        'grupoIdReal': widget.grupo.grupoIdReal,
        'presentes': p,
        'ausentes': a,
        'retardos': r,
        'detalles': detalles,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Asistencia guardada"), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ======================================================
  // ➕ AGREGAR ALUMNO NUEVO 
  // ======================================================
  Future<void> _mostrarDialogoAgregarAlumno() async {
    final nombreCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text("Nuevo alumno"),
        content: TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dContext), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('alumnos').add({
                'id': DateTime.now().millisecondsSinceEpoch,
                'nombre': nombreCtrl.text,
                'grupoId': widget.grupo.grupoIdReal,
              });
              Navigator.pop(dContext);
            }, 
            child: const Text("Guardar")
          ),
        ],
      ),
    );
  }

  void _cambiarEstado(int alumnoId, EstadoAsistencia nuevoEstado) {
    setState(() => _estados[alumnoId] = nuevoEstado);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return PasarListaScaffoldFrame(
      grupo: widget.grupo,
      fechaTexto: "${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}",
      presentes: _estados.values.where((e) => e == EstadoAsistencia.presente).length,
      ausentes: _estados.values.where((e) => e == EstadoAsistencia.ausente).length,
      retardos: _estados.values.where((e) => e == EstadoAsistencia.retardo).length,
      saving: _saving,
      onCancel: () => Navigator.pop(context),
      onSave: _guardarAsistencia,
      onMarkAll: (est) => setState(() => _estados.forEach((k, v) => _estados[k] = est)),
      onSelectDate: () async {
        final pick = await showDatePicker(context: context, initialDate: _fechaSeleccionada, firstDate: DateTime(2024), lastDate: DateTime.now());
        if (pick != null) setState(() => _fechaSeleccionada = pick);
      },
      onAddStudent: _mostrarDialogoAgregarAlumno,
      onOpenHistory: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialAsistenciasScreen(grupo: widget.grupo))),
      onExport: _exportarAExcel, // <--- ESTO ES LO QUE DA ERROR AHORA
      body: isDesktop
          ? PasarListaDesktopTable(alumnos: widget.alumnos, estados: _estados, notas: _notaControllers, onSelectEstado: _cambiarEstado)
          : PasarListaMobileList(alumnos: widget.alumnos, estados: _estados, notas: _notaControllers, onSelectEstado: _cambiarEstado, onEditNota: (a) async {}),
    );
  }
}