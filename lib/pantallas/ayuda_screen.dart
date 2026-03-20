import 'package:app_calificaciones/soporte/solucion1_soporte.dart';
import 'package:app_calificaciones/soporte/solucion2_soporte.dart';
import 'package:app_calificaciones/soporte/solucion3_soporte.dart';
import 'package:app_calificaciones/soporte/solucion4_soporte.dart';
import 'package:app_calificaciones/soporte/solucion5_soporte.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  static const Color _primaryBlue = Color(0xFF2D63ED);
  static const Color _darkBlue = Color(0xFF1E3A8A);
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textSoft = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  static const List<_SupportIssue> _issues = [
    _SupportIssue(
      title: 'No puedo iniciar sesion',
      description: 'Recupera el acceso, revisa permisos y envia reporte.',
      icon: Icons.lock_person_rounded,
      tint: _primaryBlue,
      destination: Solution1Soporte(),
    ),
    _SupportIssue(
      title: 'Error de conexion',
      description: 'Diagnostica red, carga y sincronizacion del sistema.',
      icon: Icons.wifi_tethering_error_rounded,
      tint: Color(0xFFF59E0B),
      destination: Solution2Soporte(),
    ),
    _SupportIssue(
      title: 'La aplicacion se cierra',
      description: 'Guia de estabilidad para caidas, bloqueos y reinicios.',
      icon: Icons.bug_report_rounded,
      tint: Color(0xFFEF4444),
      destination: Solution3Soporte(),
    ),
    _SupportIssue(
      title: 'No cargan las calificaciones',
      description: 'Revisa historial, materias y visibilidad academica.',
      icon: Icons.fact_check_rounded,
      tint: Color(0xFF10B981),
      destination: Solution4Soporte(),
    ),
    _SupportIssue(
      title: 'Error al subir archivos',
      description: 'Valida formatos, tamano y fallas del servidor.',
      icon: Icons.upload_file_rounded,
      tint: Color(0xFF8B5CF6),
      destination: Solution5Soporte(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 1100 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 28 : 20,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildHeroCard(isWide),
                      const SizedBox(height: 20),
                      _sectionTitle('Problemas frecuentes'),
                      const SizedBox(height: 12),
                      _buildIssuesGrid(context, isWide),
                      const SizedBox(height: 20),
                      _sectionTitle('Como te ayudamos'),
                      const SizedBox(height: 12),
                      _buildWorkflow(isWide),
                      const SizedBox(height: 20),
                      _sectionTitle('Canales de soporte'),
                      const SizedBox(height: 12),
                      _buildContactSection(context, isWide),
                      const SizedBox(height: 16),
                      _buildClosingNote(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _primaryBlue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: _primaryBlue,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Ayuda y soporte',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Encuentra la solucion correcta y envia un reporte tecnico cuando haga falta.',
                style: TextStyle(
                  color: _textSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(bool isWide) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryBlue, _darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isWide
            ? Row(
                children: [
                  Expanded(child: _buildHeroText()),
                  const SizedBox(width: 18),
                  _buildHeroStats(),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroText(),
                  const SizedBox(height: 16),
                  _buildHeroStats(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'SOPORTE DOCENTE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Te ayudamos a resolver problemas sin salir del panel.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cada guia incluye pasos claros y un formulario para registrar el incidente en la base de datos cuando necesites seguimiento.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStats() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _HeroPill(icon: Icons.menu_book_rounded, text: '5 guias listas'),
        _HeroPill(icon: Icons.cloud_done_rounded, text: 'Reportes guardados'),
        _HeroPill(icon: Icons.schedule_rounded, text: 'Respuesta prioritaria'),
      ],
    );
  }

  Widget _buildIssuesGrid(BuildContext context, bool isWide) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _issues.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 2 : 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 1.65 : 1.22,
      ),
      itemBuilder: (context, index) => _buildIssueCard(context, _issues[index]),
    );
  }

  Widget _buildIssueCard(BuildContext context, _SupportIssue issue) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => issue.destination),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: issue.tint.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(issue.icon, color: issue.tint, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Ver solucion',
                    style: TextStyle(
                      color: _textSoft,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              issue.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              issue.description,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSoft,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: _primaryBlue,
                ),
                SizedBox(width: 4),
                Text(
                  'Abrir guia y reporte',
                  style: TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflow(bool isWide) {
    final items = const [
      _WorkflowItem(
        icon: Icons.search_rounded,
        title: 'Identifica el problema',
        description: 'Selecciona la guia que mejor coincide con el incidente.',
      ),
      _WorkflowItem(
        icon: Icons.rule_folder_rounded,
        title: 'Sigue los pasos',
        description: 'Aplica acciones rapidas antes de escalar a soporte.',
      ),
      _WorkflowItem(
        icon: Icons.outbox_rounded,
        title: 'Envia el reporte',
        description: 'El caso queda registrado para seguimiento tecnico.',
      ),
    ];

    if (isWide) {
      return Row(
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: item == items.last ? 0 : 12,
                  ),
                  child: _buildWorkflowCard(item),
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWorkflowCard(item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWorkflowCard(_WorkflowItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: _primaryBlue),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: const TextStyle(
              color: _textSoft,
              fontWeight: FontWeight.w600,
              fontSize: 12.8,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, bool isWide) {
    final children = [
      _buildContactCard(
        context: context,
        icon: Icons.email_outlined,
        title: 'Correo institucional',
        subtitle: 'soporte@colegio.com',
        helper: 'Ideal para reportes y seguimiento.',
        valueToCopy: 'soporte@colegio.com',
      ),
      _buildContactCard(
        context: context,
        icon: Icons.phone_in_talk_rounded,
        title: 'Linea de soporte',
        subtitle: '+52 55 1234 5678',
        helper: 'Horario de atencion: lunes a viernes, 9:00 a 18:00.',
        valueToCopy: '+52 55 1234 5678',
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: 12),
          Expanded(child: children[1]),
        ],
      );
    }

    return Column(
      children: [
        children[0],
        const SizedBox(height: 12),
        children[1],
      ],
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String helper,
    required String valueToCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _primaryBlue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _darkBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  helper,
                  style: const TextStyle(
                    color: _textSoft,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            onPressed: () => _copyToClipboard(context, valueToCopy),
            icon: const Icon(Icons.copy_rounded, color: _textSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline_rounded, color: _primaryBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Si tu caso no aparece en la lista, abre la guia mas cercana y describe el incidente. El reporte llegara igualmente a soporte tecnico.',
              style: TextStyle(
                color: _textSoft,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w900,
        color: Color(0xFF334155),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dato copiado al portapapeles'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _SupportIssue {
  final String title;
  final String description;
  final IconData icon;
  final Color tint;
  final Widget destination;

  const _SupportIssue({
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
    required this.destination,
  });
}

class _WorkflowItem {
  final IconData icon;
  final String title;
  final String description;

  const _WorkflowItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
