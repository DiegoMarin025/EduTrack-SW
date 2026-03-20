import 'dart:html' as html;
import 'dart:typed_data';

import 'file_download_service_base.dart';

FileDownloadService createFileDownloadService() => _WebFileDownloadService();

class _WebFileDownloadService implements FileDownloadService {
  @override
  Future<String> saveBytes({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    final blob = html.Blob(<dynamic>[Uint8List.fromList(bytes)], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    return 'Descarga iniciada: $fileName';
  }
}
