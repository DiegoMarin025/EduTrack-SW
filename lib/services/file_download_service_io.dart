import 'dart:io';

import 'file_download_service_base.dart';

FileDownloadService createFileDownloadService() => _IoFileDownloadService();

class _IoFileDownloadService implements FileDownloadService {
  @override
  Future<String> saveBytes({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    final directory = await _resolveDirectory();
    final file = File(_buildUniquePath(directory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Directory> _resolveDirectory() async {
    final home =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];

    final candidates = <String>[
      if (home != null) '$home${Platform.pathSeparator}Downloads',
      if (home != null) '$home${Platform.pathSeparator}Documents',
      Directory.current.path,
      Directory.systemTemp.path,
    ];

    for (final path in candidates) {
      final directory = Directory(path);
      if (await directory.exists()) {
        return directory;
      }
    }

    return Directory.systemTemp;
  }

  String _buildUniquePath(String directoryPath, String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex >= 0 ? fileName.substring(0, dotIndex) : fileName;
    final extension = dotIndex >= 0 ? fileName.substring(dotIndex) : '';

    var candidate = '$directoryPath${Platform.pathSeparator}$fileName';
    var counter = 1;

    while (File(candidate).existsSync()) {
      candidate =
          '$directoryPath${Platform.pathSeparator}$baseName-$counter$extension';
      counter++;
    }

    return candidate;
  }
}
