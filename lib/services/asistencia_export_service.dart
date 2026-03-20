import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import 'asistencia_service.dart';
import 'file_download_service.dart';

enum AsistenciaExportFormat { pdf, word, excel }

extension AsistenciaExportFormatX on AsistenciaExportFormat {
  String get label {
    switch (this) {
      case AsistenciaExportFormat.pdf:
        return 'PDF';
      case AsistenciaExportFormat.word:
        return 'Word';
      case AsistenciaExportFormat.excel:
        return 'Excel';
    }
  }

  String get extension {
    switch (this) {
      case AsistenciaExportFormat.pdf:
        return 'pdf';
      case AsistenciaExportFormat.word:
        return 'doc';
      case AsistenciaExportFormat.excel:
        return 'xls';
    }
  }

  String get mimeType {
    switch (this) {
      case AsistenciaExportFormat.pdf:
        return 'application/pdf';
      case AsistenciaExportFormat.word:
        return 'application/msword';
      case AsistenciaExportFormat.excel:
        return 'application/vnd.ms-excel';
    }
  }
}

class AsistenciaExportResult {
  final String fileName;
  final String location;

  const AsistenciaExportResult({
    required this.fileName,
    required this.location,
  });
}

class AsistenciaExportService {
  AsistenciaExportService({FileDownloadService? fileDownloadService})
    : _fileDownloadService =
          fileDownloadService ?? createFileDownloadService();

  final FileDownloadService _fileDownloadService;
  final DateFormat _fileDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');

  Future<AsistenciaExportResult> exportar({
    required AsistenciaRegistro registro,
    required AsistenciaExportFormat format,
  }) async {
    final fileName = _buildFileName(registro, format);
    final bytes = switch (format) {
      AsistenciaExportFormat.pdf => _buildPdfBytes(registro),
      AsistenciaExportFormat.word => _buildWordBytes(registro),
      AsistenciaExportFormat.excel => _buildExcelBytes(registro),
    };

    final location = await _fileDownloadService.saveBytes(
      fileName: fileName,
      mimeType: format.mimeType,
      bytes: bytes,
    );

    return AsistenciaExportResult(fileName: fileName, location: location);
  }

  String _buildFileName(
    AsistenciaRegistro registro,
    AsistenciaExportFormat format,
  ) {
    final date = _fileDateFormat.format(registro.fecha);
    final grupo = _slug(registro.grupoNombre);
    final materia = _slug(registro.materia);
    return 'asistencia_${grupo}_${materia}_$date.${format.extension}';
  }

  Uint8List _buildWordBytes(AsistenciaRegistro registro) {
    final html = _buildHtmlDocument(
      registro: registro,
      title: 'Detalle de asistencia',
      excelMode: false,
    );
    return Uint8List.fromList(utf8.encode(html));
  }

  Uint8List _buildExcelBytes(AsistenciaRegistro registro) {
    final html = _buildHtmlDocument(
      registro: registro,
      title: 'Detalle de asistencia',
      excelMode: true,
    );
    return Uint8List.fromList(utf8.encode(html));
  }

  Uint8List _buildPdfBytes(AsistenciaRegistro registro) {
    final lines = _buildPdfLines(registro);
    const linesPerPage = 40;
    final pages = <List<String>>[];

    for (var i = 0; i < lines.length; i += linesPerPage) {
      final end = (i + linesPerPage < lines.length)
          ? i + linesPerPage
          : lines.length;
      pages.add(lines.sublist(i, end));
    }

    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [${List.generate(pages.length, (index) => '${4 + (index * 2)} 0 R').join(' ')}] /Count ${pages.length} >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    ];

    for (var index = 0; index < pages.length; index++) {
      final pageObjectNumber = 4 + (index * 2);
      final contentObjectNumber = pageObjectNumber + 1;
      final content = _buildPdfPageContent(pages[index]);
      final contentLength = ascii.encode(content).length;

      objects.add(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents $contentObjectNumber 0 R >>',
      );
      objects.add(
        '<< /Length $contentLength >>\nstream\n$content\nendstream',
      );
    }

    final builder = BytesBuilder();
    void writeAscii(String value) => builder.add(ascii.encode(value));

    writeAscii('%PDF-1.4\n');
    final offsets = <int>[];

    for (var i = 0; i < objects.length; i++) {
      offsets.add(builder.length);
      writeAscii('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
    }

    final xrefOffset = builder.length;
    writeAscii('xref\n0 ${objects.length + 1}\n');
    writeAscii('0000000000 65535 f \n');
    for (final offset in offsets) {
      writeAscii('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    writeAscii(
      'trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF',
    );

    return builder.toBytes();
  }

  String _buildHtmlDocument({
    required AsistenciaRegistro registro,
    required String title,
    required bool excelMode,
  }) {
    final rows = registro.detalles
        .map((detalle) {
          final nota = detalle.nota.trim().isEmpty ? 'Sin nota' : detalle.nota;
          return '''
            <tr>
              <td>${_html(detalle.nombreAlumno)}</td>
              <td>${_html(detalle.correoAlumno)}</td>
              <td>${_html(_estadoTexto(detalle.estado))}</td>
              <td>${_html(nota)}</td>
            </tr>
          ''';
        })
        .join();

    final headPrefix = excelMode
        ? '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">'
        : '<html>';

    return '''
      $headPrefix
        <head>
          <meta charset="utf-8">
          <title>${_html(title)}</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 24px; color: #0f172a; }
            h1 { margin-bottom: 6px; }
            .meta { margin: 2px 0; color: #475569; }
            .summary { margin: 16px 0; display: flex; gap: 12px; }
            .pill {
              display: inline-block;
              padding: 8px 12px;
              border-radius: 999px;
              background: #f1f5f9;
              margin-right: 8px;
              font-weight: 700;
            }
            table { width: 100%; border-collapse: collapse; margin-top: 18px; }
            th, td { border: 1px solid #cbd5e1; padding: 10px; text-align: left; }
            th { background: #e2e8f0; font-weight: 800; }
            tr:nth-child(even) { background: #f8fafc; }
          </style>
        </head>
        <body>
          <h1>${_html(title)}</h1>
          <div class="meta"><strong>Grupo:</strong> ${_html(registro.grupoNombre)}</div>
          <div class="meta"><strong>Materia:</strong> ${_html(registro.materia)}</div>
          <div class="meta"><strong>Fecha:</strong> ${_html(_displayDateFormat.format(registro.fecha))}</div>

          <div class="summary">
            <span class="pill">Presentes: ${registro.presentes}</span>
            <span class="pill">Ausentes: ${registro.ausentes}</span>
            <span class="pill">Retardos: ${registro.retardos}</span>
          </div>

          <table>
            <thead>
              <tr>
                <th>Alumno</th>
                <th>Correo</th>
                <th>Estado</th>
                <th>Nota</th>
              </tr>
            </thead>
            <tbody>
              $rows
            </tbody>
          </table>
        </body>
      </html>
    ''';
  }

  List<String> _buildPdfLines(AsistenciaRegistro registro) {
    final lines = <String>[
      'Detalle de asistencia',
      'Grupo: ${registro.grupoNombre}',
      'Materia: ${registro.materia}',
      'Fecha: ${_displayDateFormat.format(registro.fecha)}',
      'Presentes: ${registro.presentes} | Ausentes: ${registro.ausentes} | Retardos: ${registro.retardos}',
      '',
      'Alumno | Correo | Estado | Nota',
      '',
    ];

    for (final detalle in registro.detalles) {
      final nota = detalle.nota.trim().isEmpty ? 'Sin nota' : detalle.nota;
      lines.add(
        '${detalle.nombreAlumno} | ${detalle.correoAlumno} | ${_estadoTexto(detalle.estado)} | ${nota.replaceAll('\n', ' ')}',
      );
    }

    return lines.map(_normalizePdfLine).toList();
  }

  String _buildPdfPageContent(List<String> lines) {
    final buffer = StringBuffer()
      ..writeln('BT')
      ..writeln('/F1 11 Tf')
      ..writeln('50 760 Td');

    for (var i = 0; i < lines.length; i++) {
      if (i > 0) {
        buffer.writeln('0 -16 Td');
      }
      buffer.writeln('(${_escapePdfText(lines[i])}) Tj');
    }

    buffer.writeln('ET');
    return buffer.toString();
  }

  String _estadoTexto(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return 'Presente';
      case EstadoAsistencia.ausente:
        return 'Ausente';
      case EstadoAsistencia.retardo:
        return 'Retardo';
    }
  }

  String _slug(String value) {
    final asciiValue = _toAscii(value).toLowerCase();
    final normalized = asciiValue.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _html(String value) => const HtmlEscape().convert(value);

  String _normalizePdfLine(String value) {
    final asciiValue = _toAscii(value).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (asciiValue.length <= 95) {
      return asciiValue;
    }
    return '${asciiValue.substring(0, 92)}...';
  }

  String _escapePdfText(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)');
  }

  String _toAscii(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      switch (rune) {
        case 0x00E1:
        case 0x00E0:
        case 0x00E4:
        case 0x00E2:
          buffer.write('a');
          break;
        case 0x00C1:
        case 0x00C0:
        case 0x00C4:
        case 0x00C2:
          buffer.write('A');
          break;
        case 0x00E9:
        case 0x00E8:
        case 0x00EB:
        case 0x00EA:
          buffer.write('e');
          break;
        case 0x00C9:
        case 0x00C8:
        case 0x00CB:
        case 0x00CA:
          buffer.write('E');
          break;
        case 0x00ED:
        case 0x00EC:
        case 0x00EF:
        case 0x00EE:
          buffer.write('i');
          break;
        case 0x00CD:
        case 0x00CC:
        case 0x00CF:
        case 0x00CE:
          buffer.write('I');
          break;
        case 0x00F3:
        case 0x00F2:
        case 0x00F6:
        case 0x00F4:
          buffer.write('o');
          break;
        case 0x00D3:
        case 0x00D2:
        case 0x00D6:
        case 0x00D4:
          buffer.write('O');
          break;
        case 0x00FA:
        case 0x00F9:
        case 0x00FC:
        case 0x00FB:
          buffer.write('u');
          break;
        case 0x00DA:
        case 0x00D9:
        case 0x00DC:
        case 0x00DB:
          buffer.write('U');
          break;
        case 0x00F1:
          buffer.write('n');
          break;
        case 0x00D1:
          buffer.write('N');
          break;
        case 0x2022:
          buffer.write('-');
          break;
        case 0x201C:
        case 0x201D:
          buffer.write('"');
          break;
        case 0x2019:
          buffer.write("'");
          break;
        default:
          buffer.write(String.fromCharCode(rune));
      }
    }
    return buffer.toString();
  }
}
