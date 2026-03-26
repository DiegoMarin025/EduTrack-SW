import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/local_demo_store.dart'; 

class MensajesPadresScreen extends StatefulWidget {
  final String profesorId;
  const MensajesPadresScreen({super.key, required this.profesorId});

  @override
  State<MensajesPadresScreen> createState() => _MensajesPadresScreenState();
}

class _MensajesPadresScreenState extends State<MensajesPadresScreen> {
  final Color primaryBlue = const Color(0xFF2D63ED);
  final Color darkBlue = const Color(0xFF1E3A8A);
  final Color bgLight = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Buzón de Seguimiento', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🟢 BUSQUEDA EN LA COLECCIÓN DE REPORTES
        stream: FirebaseFirestore.instance
            .collection('reportes_seguimiento')
            .where('profesorId', isEqualTo: widget.profesorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) return _buildEmptyState();

          final sortedDocs = List.from(docs);
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
          });

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeroCard(),
              const SizedBox(height: 16),
              _buildStatsRow(docs), 
              const SizedBox(height: 18),
              const Text(
                'Reportes y solicitudes recibidas',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              ...sortedDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id; 
                return _buildItemCard(data);
              }),
            ],
          );
        },
      ),
    );
  }

  // --- MÉTODOS DE DISEÑO ADAPTADOS A LOS REPORTES ---

  Widget _buildStatsRow(List<QueryDocumentSnapshot> docs) {
    return Row(
      children: [
        Expanded(child: _statCard(value: '${docs.length}', label: 'Total', icon: Icons.mail_outline_rounded, tint: primaryBlue)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(value: '${docs.length}', label: 'Nuevos', icon: Icons.campaign_rounded, tint: const Color(0xFFF59E0B))),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'Recibido').toString();
    final categoria = item['categoria'] ?? 'Reporte';
    final isGrave = categoria.toString().toLowerCase().contains('denuncia');
    final color = isGrave ? Colors.redAccent : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: isGrave ? Colors.redAccent.withOpacity(0.3) : const Color(0xFFE2E8F0))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
                child: Icon(isGrave ? Icons.gavel_rounded : Icons.campaign_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['asunto'] ?? 'Sin asunto', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                    Text('De: ${item['tutorNombre'] ?? 'Tutor'} | Alumno: ${item['alumnoNombre'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              _badge(status, color),
            ],
          ),
          const SizedBox(height: 12),
          _infoLine(Icons.category_rounded, "Categoría: $categoria"),
          if (item['materia'] != null && item['materia'] != 'General') ...[
            const SizedBox(height: 4),
            _infoLine(Icons.book_rounded, "Materia: ${item['materia']}"),
          ],
          const SizedBox(height: 8),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
            child: Text(item['detalle'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          ),
          if (item['hasAttachment'] == true) ...[
            const SizedBox(height: 12),
            _buildLocalAdjuntoWidget(item['id']),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalAdjuntoWidget(String docId) {
    final localFile = LocalDemoStore.justificantesLocales[docId];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.attach_file, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text("Evidencia Adjunta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          if (localFile != null) ...[
            const SizedBox(height: 10),
            Image.network(localFile.path, height: 150, width: double.infinity, fit: BoxFit.cover),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("(Imagen cargada en el dispositivo)", style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _statCard({required String value, required String label, required IconData icon, required Color tint}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Icon(icon, color: tint),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryBlue, darkBlue]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text('BUZÓN DEL DOCENTE\nRevisa los reportes y solicitudes de los tutores.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() => const Center(child: Padding(
    padding: EdgeInsets.all(40.0),
    child: Text("No hay reportes ni solicitudes para ti.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
  ));
  
  Widget _badge(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  
  Widget _infoLine(IconData icon, String text) => Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 5), Text(text, style: const TextStyle(fontSize: 12))]);
}