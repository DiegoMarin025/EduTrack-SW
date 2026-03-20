abstract class FileDownloadService {
  Future<String> saveBytes({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  });
}
